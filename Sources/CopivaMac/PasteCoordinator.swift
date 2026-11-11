import AppKit
import ApplicationServices
import CopivaCore

public enum PasteOutcome: Equatable, Sendable {
    case pasteRequested
    case copiedPermissionRequired
    case copiedFocusChanged
    case copiedUnavailable
    case copyFailed
    case cancelled
    case busy

    public var message: String {
        switch self {
        case .pasteRequested: "Paste requested in the destination app."
        case .copiedPermissionRequired: "Copied. Enable Copiva in Accessibility settings, then open the picker again. You can also paste with Command-V."
        case .copiedFocusChanged: "Copied. The destination changed or could not be verified; use Command-V where you want the text."
        case .copiedUnavailable: "Copied. Automatic paste is unavailable; use Command-V in the destination app."
        case .copyFailed: "Copy failed. No paste was sent."
        case .cancelled: "Paste cancelled."
        case .busy: "A paste action is already in progress."
        }
    }
}

/// Boundary for permission, focus and event posting; tests substitute synthetic state.
@MainActor
protocol PasteAccess: AnyObject {
    var isTrusted: Bool { get }
    var hasTarget: Bool { get }
    var targetIsFocused: Bool { get }
    var modifiersAreReleased: Bool { get }
    var clipboardChangeCount: Int { get }
    func requestPermission()
    func captureTarget()
    func postCommandV(expectedClipboardChangeCount: Int) -> Bool
}

@MainActor
public final class PasteCoordinator {
    private let access: any PasteAccess
    private var generation: UInt64 = 0
    private var isPasting = false

    public convenience init() { self.init(access: SystemPasteAccess()) }

    init(access: any PasteAccess) { self.access = access }

    public func prepare() {
        generation &+= 1
        access.captureTarget()
    }

    public func cancel() { generation &+= 1 }

    public func paste(_ clip: TextClip, dismiss: () -> Void,
                      copy: (TextClip) -> Int?) async -> PasteOutcome {
        guard !Task.isCancelled else { return .cancelled }
        guard !isPasting else { return .busy }
        isPasting = true
        defer { isPasting = false }
        let intent = generation
        guard access.isTrusted else {
            // Permission is requested only by this explicit Paste action.
            access.requestPermission()
            return copy(clip) != nil ? .copiedPermissionRequired : .copyFailed
        }
        guard access.hasTarget, access.targetIsFocused else {
            return copy(clip) != nil ? .copiedFocusChanged : .copyFailed
        }
        dismiss()
        let deadline = ContinuousClock.now.advanced(by: .milliseconds(600))
        while !access.modifiersAreReleased && ContinuousClock.now < deadline {
            do { try await Task.sleep(for: .milliseconds(20)) }
            catch { return .cancelled }
            guard generation == intent else { return .cancelled }
        }
        // Allow the nonactivating panel's keyboard focus to return to the target.
        do { try await Task.sleep(for: .milliseconds(40)) }
        catch { return .cancelled }
        guard generation == intent, !Task.isCancelled else { return .cancelled }
        guard access.isTrusted, access.targetIsFocused else {
            return copy(clip) != nil ? .copiedFocusChanged : .copyFailed
        }
        guard let revision = copy(clip) else { return .copyFailed }
        guard access.modifiersAreReleased, access.targetIsFocused,
              access.clipboardChangeCount == revision,
              access.postCommandV(expectedClipboardChangeCount: revision) else { return .copiedUnavailable }
        return .pasteRequested
    }
}

@MainActor
private final class SystemPasteAccess: PasteAccess {
    private var app: NSRunningApplication?
    private var focusedElement: AXUIElement?

    var isTrusted: Bool { AXIsProcessTrusted() }
    var hasTarget: Bool { app != nil && focusedElement != nil }

    func requestPermission() {
        // The public option key avoids importing a mutable C global into Swift concurrency.
        let key = "AXTrustedCheckOptionPrompt"
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    func captureTarget() {
        app = nil
        focusedElement = nil
        guard isTrusted, let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              !front.isTerminated,
              let focus = focusedTextElement(in: front.processIdentifier) else { return }
        app = front
        focusedElement = focus
    }

    var targetIsFocused: Bool {
        guard isTrusted, let app, !app.isTerminated, let focusedElement,
              let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier == app.processIdentifier,
              front.launchDate == app.launchDate,
              let current = focusedTextElement(in: app.processIdentifier) else { return false }
        return CFEqual(focusedElement, current)
    }

    private func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private func focusedTextElement(in pid: pid_t) -> AXUIElement? {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 0.2)
        guard let value = attribute(kAXFocusedUIElementAttribute, of: application),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeDowncast(value, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, 0.2)
        let role = attribute(kAXRoleAttribute, of: element) as? String
        let subrole = attribute(kAXSubroleAttribute, of: element) as? String
        guard [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(where: { $0 == role }),
              subrole != kAXSecureTextFieldSubrole else { return nil }
        var editable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &editable)
                == .success, editable.boolValue else { return nil }
        return element
    }

    var modifiersAreReleased: Bool {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        return flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty
    }

    var clipboardChangeCount: Int { NSPasteboard.general.changeCount }

    func postCommandV(expectedClipboardChangeCount: Int) -> Bool {
        guard clipboardChangeCount == expectedClipboardChangeCount,
              isTrusted, targetIsFocused, modifiersAreReleased,
              let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return false
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        guard targetIsFocused, modifiersAreReleased,
              clipboardChangeCount == expectedClipboardChangeCount else { return false }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}

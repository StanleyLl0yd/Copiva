import AppKit
import Carbon

public struct GlobalShortcut: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: UInt32
    public let keyLabel: String

    public init(keyCode: UInt32, modifiers: UInt32, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }

    public static let standard = GlobalShortcut(
        keyCode: 9, modifiers: UInt32(controlKey | optionKey), keyLabel: "V")

    public var isValid: Bool {
        let allowed = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        let required = UInt32(cmdKey | controlKey | optionKey)
        let modifierKeys: Set<UInt32> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        return keyCode < 128 && keyCode != 53 && !modifierKeys.contains(keyCode)
            && modifiers & ~allowed == 0 && modifiers & required != 0
            && !keyLabel.isEmpty && keyLabel.utf8.count <= 16
            && !keyLabel.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
    }

    public var displayLabel: String {
        [(controlKey, "⌃"), (optionKey, "⌥"), (shiftKey, "⇧"), (cmdKey, "⌘")]
            .filter { modifiers & UInt32($0.0) != 0 }
            .map(\.1).joined() + keyLabel
    }

    public static func from(_ event: NSEvent) -> GlobalShortcut {
        let flags = event.modifierFlags
        var modifiers: UInt32 = 0
        for (flag, carbon) in [(NSEvent.ModifierFlags.command, cmdKey),
                               (.control, controlKey), (.option, optionKey), (.shift, shiftKey)] {
            if flags.contains(flag) { modifiers |= UInt32(carbon) }
        }
        let labels: [UInt16: String] = [
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 117: "Forward Delete",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        let label = labels[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased()
            ?? "Key \(event.keyCode)"
        return GlobalShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyLabel: label)
    }
}

public enum HotkeyError: Error, Equatable, Sendable {
    case invalidShortcut
    case registrationFailed(Int32)
    case handlerFailed(Int32)
    case unregistrationFailed(Int32)
}

@MainActor
public final class GlobalHotkey {
    private static var nextID: UInt32 = 0
    private let id: UInt32
    private var handler: EventHandlerRef?
    private var registration: EventHotKeyRef?
    private let onPress: @MainActor () -> Void
    public private(set) var shortcut: GlobalShortcut?

    public init(onPress: @escaping @MainActor () -> Void) throws {
        Self.nextID &+= 1
        id = Self.nextID
        self.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let result = InstallEventHandler(
            GetApplicationEventTarget(), copivaHotkeyHandler, 1, &spec,
            Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard result == noErr else { throw HotkeyError.handlerFailed(result) }
    }

    isolated deinit {
        if let registration { UnregisterEventHotKey(registration) }
        if let handler { RemoveEventHandler(handler) }
    }

    public func register(_ candidate: GlobalShortcut) throws {
        guard candidate.isValid else { throw HotkeyError.invalidShortcut }
        if shortcut?.keyCode == candidate.keyCode, shortcut?.modifiers == candidate.modifiers {
            shortcut = candidate
            return
        }
        var newRegistration: EventHotKeyRef?
        let eventID = EventHotKeyID(signature: 0x43505641, id: id)
        let result = RegisterEventHotKey(candidate.keyCode, candidate.modifiers, eventID,
                                         GetApplicationEventTarget(), 0, &newRegistration)
        guard result == noErr, let newRegistration else {
            throw HotkeyError.registrationFailed(result)
        }
        // Register first: a conflict must not silently remove the old working shortcut.
        if let registration {
            let removal = UnregisterEventHotKey(registration)
            guard removal == noErr else {
                UnregisterEventHotKey(newRegistration)
                throw HotkeyError.unregistrationFailed(removal)
            }
        }
        registration = newRegistration
        shortcut = candidate
    }

    public func stop() {
        if let registration { UnregisterEventHotKey(registration) }
        registration = nil
        shortcut = nil
    }

    fileprivate func receive(_ eventID: EventHotKeyID) -> OSStatus {
        guard registration != nil, eventID.signature == 0x43505641, eventID.id == id else {
            return OSStatus(eventNotHandledErr)
        }
        onPress()
        return noErr
    }
}

private let copivaHotkeyHandler: EventHandlerUPP = { _, event, context in
    guard let event, let context else { return OSStatus(eventNotHandledErr) }
    var eventID = EventHotKeyID()
    let result = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  UInt32(MemoryLayout<EventHotKeyID>.size), nil, &eventID)
    guard result == noErr else { return result }
    return MainActor.assumeIsolated {
        Unmanaged<GlobalHotkey>.fromOpaque(context).takeUnretainedValue().receive(eventID)
    }
}

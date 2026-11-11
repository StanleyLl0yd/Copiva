import AppKit
import CopivaCore
import CopivaMac
import Observation
import SwiftUI

@MainActor @Observable
final class PickerState {
    var selection = PickerSelection()
    var isBusy = false
    var message: String?
}

@MainActor
final class PickerController: NSObject, NSWindowDelegate {
    private let session: HistorySession
    private let state = PickerState()
    private let paste = PasteCoordinator()
    private var panel: PickerPanel?
    private var isShowing = false

    init(session: HistorySession) { self.session = session }

    func toggle() {
        if isShowing { dismiss(); return }
        paste.prepare()
        state.message = nil
        session.query = ""
        session.search()
        state.selection.update(ids: session.clips.map(\.id))
        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: HistoryPicker(
            session: session, state: state,
            onCopy: { [weak self] in self?.copySelected() },
            onPaste: { [weak self] in self?.pasteSelected() },
            onDismiss: { [weak self] in self?.dismiss() }))
        let pointer = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) }) ?? NSScreen.main {
            panel.setFrame(PickerPlacement.frame(size: CGSize(width: 440, height: 460),
                                                pointer: pointer, visibleFrame: screen.visibleFrame),
                           display: false)
        }
        isShowing = true
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel() -> PickerPanel {
        let panel = PickerPanel(
            contentRect: CGRect(x: 0, y: 0, width: 440, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.title = "Copiva History"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.delegate = self
        panel.onMove = { [weak self] in self?.state.selection.move(by: $0) }
        panel.onChoose = { [weak self] copyOnly in
            if copyOnly { self?.copySelected() } else { self?.pasteSelected() }
        }
        panel.onCancel = { [weak self] in self?.dismiss() }
        self.panel = panel
        return panel
    }

    func dismiss() {
        paste.cancel()
        dismissForAction()
    }

    private func dismissForAction() {
        isShowing = false
        panel?.orderOut(nil)
    }

    private var selected: TextClip? {
        session.clips.first { $0.id == state.selection.selectedID }
    }

    private func copySelected() {
        guard !state.isBusy, session.isReady, !session.isBusy, let selected else { return }
        if session.copy(selected) { dismiss() }
    }

    private func pasteSelected() {
        guard !state.isBusy, session.isReady, !session.isBusy, let selected else { return }
        state.isBusy = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            let outcome = await paste.paste(
                selected, dismiss: { self.dismissForAction() },
                copy: { clip in
                    guard self.session.copy(clip) else { return nil }
                    return self.session.lastCopyChangeCount
                })
            state.message = outcome.message
            session.notice = outcome.message
            state.isBusy = false
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if isShowing { dismiss() }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        dismiss()
        return false
    }
}

@MainActor
private final class PickerPanel: NSPanel {
    var onMove: ((Int) -> Void)?
    var onChoose: ((Bool) -> Void)?
    var onCancel: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) { onCancel?() }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown,
              (firstResponder as? NSTextView)?.hasMarkedText() != true else {
            super.sendEvent(event)
            return
        }
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        if event.keyCode == 53 { onCancel?(); return }
        if modifiers.isEmpty {
            if event.keyCode == 125 { onMove?(1); return }
            if event.keyCode == 126 { onMove?(-1); return }
        }
        if [36, 76].contains(event.keyCode),
           modifiers.isEmpty || modifiers == .command {
            onChoose?(modifiers == .command)
            return
        }
        super.sendEvent(event)
    }
}

private struct HistoryPicker: View {
    @Bindable var session: HistorySession
    @Bindable var state: PickerState
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onDismiss: () -> Void
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Copiva").font(.headline)
                Spacer()
                Button("Close", action: onDismiss)
            }
            TextField("Search copied text", text: $session.query)
                .textFieldStyle(.roundedBorder).focused($searchFocused)
                .onChange(of: session.query) { session.search() }
                .disabled(!session.isReady || state.isBusy)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if session.clips.isEmpty {
                            Text(session.query.isEmpty ? "No saved copies yet." : "No matching copies.")
                                .foregroundStyle(.secondary).padding()
                        }
                        ForEach(session.clips) { clip in
                            Button {
                                state.selection.select(clip.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(verbatim: String(clip.text.prefix(300))).lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(clip.copiedAt, style: .relative)
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(10).contentShape(Rectangle())
                                .background(state.selection.selectedID == clip.id
                                            ? Color.accentColor.opacity(0.18) : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain).id(clip.id)
                            .accessibilityAddTraits(state.selection.selectedID == clip.id ? .isSelected : [])
                        }
                    }
                }
                .onChange(of: state.selection.selectedID) {
                    if let id = state.selection.selectedID { proxy.scrollTo(id) }
                }
            }
            .frame(maxHeight: .infinity)
            if let error = session.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            if let message = state.message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Copy · ⌘↩", action: onCopy)
                Spacer()
                Button("Paste · ↩", action: onPaste)
            }
            .disabled(state.selection.selectedID == nil || state.isBusy || !session.isReady || session.isBusy)
            Text("↑ ↓ choose · Esc close. If automatic paste is unavailable, the item is copied for Command-V.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(18).padding(.top, 16)
        .onAppear { searchFocused = true }
        .onChange(of: session.clips.map(\.id)) { state.selection.update(ids: session.clips.map(\.id)) }
    }
}

import AppKit
import CopivaCore
import CopivaMac
import SwiftUI

@MainActor
final class ApplicationController {
    let session = HistorySession()
    let shortcuts = ShortcutSettings()
    private let picker: PickerController

    init() { picker = PickerController(session: session) }

    func start() {
        shortcuts.start { [weak self] in self?.showPicker() }
        Task { await session.open() }
    }

    func showPicker() { picker.toggle() }

    func quit() {
        shortcuts.stop()
        picker.dismiss()
        Task {
            await session.close()
            NSApplication.shared.terminate(nil)
        }
    }
}

@main
struct CopivaApp: App {
    @State private var controller: ApplicationController

    init() {
        let controller = ApplicationController()
        _controller = State(initialValue: controller)
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra("Copiva", systemImage: "clipboard") {
            HistoryMenu(session: controller.session, shortcuts: controller.shortcuts,
                        onShowPicker: controller.showPicker, onQuit: controller.quit)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct HistoryMenu: View {
    @Bindable var session: HistorySession
    @Bindable var shortcuts: ShortcutSettings
    let onShowPicker: () -> Void
    let onQuit: () -> Void
    @State private var recordingShortcut = false
    @State private var askingConsent = false
    @State private var askingClear = false
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppInfo.displayName).font(.headline)
                Spacer()
                Text(session.isRecording ? "Recording" : "Paused")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error = session.errorMessage {
                Text(error).font(.callout).foregroundStyle(.red)
                    .accessibilityLabel("History error: " + error)
                Button("Dismiss error") { session.errorMessage = nil }
            }
            Button("Open history · " + shortcuts.shortcut.displayLabel, action: onShowPicker)
                .disabled(!session.isReady)
            if let error = shortcuts.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Button(session.isRecording ? "Pause recording" : "Record copied text") {
                    if session.isRecording {
                        session.setRecording(false)
                    } else if session.hasConsented {
                        session.setRecording(true)
                    } else {
                        askingConsent = true
                    }
                }
                .disabled(!session.isReady || session.isBusy)
                Spacer()
                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("History settings")
            }
            TextField("Search copied text", text: $session.query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: session.query) { session.search() }
                .disabled(!session.isReady)
            if session.clips.isEmpty {
                Text(session.isReady
                     ? (session.query.isEmpty ? "No saved copies yet." : "No matching copies.")
                     : "Opening history…")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(session.clips) { clip in
                            Button {
                                session.copy(clip)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(verbatim: String(clip.text.prefix(300)))
                                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                                    Text(clip.copiedAt, style: .relative)
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(8).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Copy this item to the clipboard")
                        }
                    }
                }
                .frame(height: 260)
            }
            if showingSettings {
                Divider()
                if recordingShortcut {
                    Text("Press a shortcut with Command, Control or Option. Escape cancels.")
                        .font(.caption)
                    ShortcutRecorder(onRecord: { shortcut in
                        shortcuts.change(to: shortcut)
                        recordingShortcut = false
                    }, onCancel: { recordingShortcut = false })
                    .frame(height: 28)
                    .background(Color.accentColor.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 6))
                    Button("Cancel shortcut change") { recordingShortcut = false }
                } else {
                    Button("Change shortcut…") { recordingShortcut = true }
                }
                Picker("Keep copies", selection: Binding(
                    get: { session.historyLimit },
                    set: { limit in Task { await session.changeLimit(limit) } }
                )) {
                    ForEach([100, 500, 1_000, 5_000, 10_000], id: \.self) { limit in
                        Text("\(limit)").tag(limit)
                    }
                }
                .disabled(!session.isReady || session.isBusy)
                TextField("Excluded app bundle IDs, separated by commas",
                          text: $session.excludedApplications)
                    .textFieldStyle(.roundedBorder)
                Text("Exclusions use the app in front when a copy is observed. Confidential markers are skipped, but unmarked secrets can still be saved.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Clear saved history…", role: .destructive) { askingClear = true }
                    .disabled(!session.isReady || session.isBusy)
            }
            if let notice = session.notice {
                Text(notice).font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Button("Quit Copiva", action: onQuit)
        }
        .padding(16).frame(width: 380)
        .alert("Save copied text on this Mac?", isPresented: $askingConsent) {
            Button("Enable recording") { session.setRecording(true, consent: true) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("New text copies will be stored locally, without encryption. Copiva skips recognized confidential markers, but cannot identify every password or secret. macOS may also ask to allow clipboard access. You can pause recording, exclude apps, or clear history in settings.")
        }
        .alert("Clear all saved history?", isPresented: $askingClear) {
            Button("Clear history", role: .destructive) {
                Task { await session.clearHistory() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes saved text copies from Copiva. It does not change your current clipboard. Filesystem backups may retain older data.")
        }
    }
}

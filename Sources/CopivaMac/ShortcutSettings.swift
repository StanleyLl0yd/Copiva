import AppKit
import Observation

@MainActor @Observable
public final class ShortcutSettings {
    public private(set) var shortcut: GlobalShortcut
    public private(set) var isRegistered = false
    public var errorMessage: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var hotkey: GlobalHotkey?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "globalShortcut"),
           let saved = try? JSONDecoder().decode(GlobalShortcut.self, from: data), saved.isValid {
            shortcut = saved
        } else {
            shortcut = .standard
        }
    }

    public func start(onPress: @escaping @MainActor () -> Void) {
        guard hotkey == nil else { return }
        do {
            let hotkey = try GlobalHotkey(onPress: onPress)
            self.hotkey = hotkey
            try hotkey.register(shortcut)
            isRegistered = true
        } catch {
            errorMessage = "The global shortcut is unavailable. Choose another shortcut in settings."
        }
    }

    public func change(to candidate: GlobalShortcut) {
        guard candidate.isValid else {
            errorMessage = "Use Command, Control or Option with a key. Escape cancels recording."
            return
        }
        do {
            guard let hotkey else {
                errorMessage = "The shortcut handler is unavailable. Close and reopen Copiva."
                return
            }
            let data = try JSONEncoder().encode(candidate)
            try hotkey.register(candidate)
            shortcut = candidate
            defaults.set(data, forKey: "globalShortcut")
            errorMessage = nil
            isRegistered = true
        } catch {
            errorMessage = "That shortcut is already in use or unavailable. The previous shortcut has been kept."
        }
    }

    public func stop() {
        hotkey?.stop()
        hotkey = nil
        isRegistered = false
    }
}

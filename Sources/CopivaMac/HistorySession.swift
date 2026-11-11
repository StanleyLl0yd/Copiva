import AppKit
import CopivaCore
import Observation

@MainActor @Observable
public final class HistorySession {
    public private(set) var clips: [TextClip] = []
    public private(set) var isReady = false
    public private(set) var isBusy = false
    public private(set) var isRecording = false
    public private(set) var hasConsented: Bool
    public private(set) var historyLimit: Int
    public var query = ""
    public var errorMessage: String?
    public var notice: String?
    public private(set) var lastCopyChangeCount: Int?
    public var excludedApplications: String {
        didSet { defaults.set(excludedApplications, forKey: "excludedApplications") }
    }

    @ObservationIgnored private let monitor: ClipboardMonitor
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let directory: URL?
    @ObservationIgnored private var store: HistoryStore?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var reloadGeneration: UInt64 = 0
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    public init(directory: URL? = nil, defaults: UserDefaults = .standard,
                pasteboard: NSPasteboard = .general) {
        self.directory = directory
        self.defaults = defaults
        monitor = ClipboardMonitor(pasteboard: pasteboard)
        hasConsented = defaults.bool(forKey: "captureConsent")
        let savedLimit = defaults.integer(forKey: "historyLimit")
        historyLimit = (1...HistoryStore.maximumHistoryCount).contains(savedLimit) ? savedLimit : 500
        excludedApplications = defaults.string(forKey: "excludedApplications") ?? ""
    }

    public func open() async {
        guard !started else { return }
        started = true
        isBusy = true
        defer { isBusy = false }
        do {
            let location: URL
            if let directory {
                location = directory
            } else {
                location = try FileManager.default.url(
                    for: .applicationSupportDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true)
                    .appendingPathComponent("Copiva/History", isDirectory: true)
            }
            let limit = historyLimit
            store = try await Task.detached(priority: .utility) {
                try HistoryStore(directory: location, limit: limit)
            }.value
            isReady = true
            if hasConsented && defaults.bool(forKey: "recordingEnabled") {
                setRecording(true)
            }
            await reload()
            pollingTask = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(350)) }
                    catch { return }
                    guard let self else { return }
                    await self.pollOnce()
                }
            }
        } catch {
            errorMessage = "History could not be opened. Existing files have been kept. Quit and check the app's storage before trying again."
        }
    }

    public func setRecording(_ enabled: Bool, consent: Bool = false) {
        guard isReady else { return }
        guard !enabled || hasConsented || consent else { return }
        if consent {
            hasConsented = true
            defaults.set(true, forKey: "captureConsent")
        }
        monitor.setRecording(enabled)
        isRecording = enabled
        defaults.set(enabled, forKey: "recordingEnabled")
        notice = enabled ? "Recording new text copies." : "Recording paused."
    }

    func pollOnce() async {
        guard !isBusy, let store else { return }
        let excluded = Set(excludedApplications.split { $0 == "," || $0.isWhitespace }.map(String.init))
        guard let text = monitor.readNewText(
            sourceBundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            excludedBundleIDs: excluded) else { return }
        do {
            _ = try await store.record(text)
            await reload()
        } catch {
            setRecording(false)
            errorMessage = "Recording stopped because history could not be saved. Existing files have been kept."
        }
    }

    public func search() {
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)) }
            catch { return }
            await self?.reload()
        }
    }

    private func reload() async {
        guard let store else { return }
        reloadGeneration &+= 1
        let generation = reloadGeneration
        let expectedQuery = query
        do {
            let results = try await store.search(expectedQuery)
            guard !Task.isCancelled, isReady, reloadGeneration == generation,
                  query == expectedQuery else { return }
            clips = results
        } catch {
            guard !Task.isCancelled, isReady, reloadGeneration == generation,
                  query == expectedQuery else { return }
            clips = []
            if error as? HistoryError == .invalidQuery {
                errorMessage = "Keep the search under 512 bytes and 32 words."
            } else {
                setRecording(false)
                isReady = false
                errorMessage = "History could not be read. Recording stopped and existing files have been kept."
            }
        }
    }

    @discardableResult
    public func copy(_ clip: TextClip) -> Bool {
        let copied = monitor.copyText(clip.text)
        lastCopyChangeCount = monitor.lastWriteChangeCount
        notice = copied ? "Copied. Use Command-V in the destination app." : "Copy failed. Try again."
        return copied
    }

    public func changeLimit(_ limit: Int) async {
        guard !isBusy, let store else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await store.setLimit(limit)
            historyLimit = limit
            defaults.set(limit, forKey: "historyLimit")
            await reload()
        } catch {
            errorMessage = "The history limit could not be changed. The previous setting has been kept."
        }
    }

    /// The view must obtain explicit confirmation before calling this operation.
    public func clearHistory() async {
        guard !isBusy, let store else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await store.clearOrdinaryHistory()
            await reload()
            notice = "History cleared."
        } catch {
            errorMessage = "History could not be cleared. No automatic reset was attempted."
        }
    }

    public func close() async {
        reloadGeneration &+= 1
        pollingTask?.cancel()
        searchTask?.cancel()
        pollingTask = nil
        searchTask = nil
        monitor.setRecording(false)
        isRecording = false
        isReady = false
        await store?.close()
        store = nil
    }
}

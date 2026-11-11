import AppKit
import CopivaCore
import XCTest
@testable import CopivaMac

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    private func board() -> NSPasteboard {
        NSPasteboard(name: .init("copiva-synthetic-tests-\(UUID().uuidString)"))
    }

    private func write(_ text: String, to board: NSPasteboard,
                       types: [NSPasteboard.PasteboardType] = []) {
        let item = NSPasteboardItem()
        XCTAssertTrue(item.setString(text, forType: .string))
        for type in types { XCTAssertTrue(item.setData(Data(), forType: type)) }
        board.clearContents()
        XCTAssertTrue(board.writeObjects([item]))
    }

    private func read(_ monitor: ClipboardMonitor,
                      source: String? = "test.synthetic.app",
                      exclusions: Set<String> = []) -> String? {
        monitor.readNewText(sourceBundleID: source, excludedBundleIDs: exclusions)
    }

    func testConsentResumeAndPauseNeverImportExistingClipboard() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        write("before consent", to: board)
        XCTAssertNil(read(monitor))
        monitor.setRecording(true)
        XCTAssertNil(read(monitor))
        write("after consent", to: board)
        XCTAssertEqual(read(monitor), "after consent")
        XCTAssertNil(read(monitor))
        monitor.setRecording(false)
        write("during pause", to: board)
        XCTAssertNil(read(monitor))
        monitor.setRecording(true)
        XCTAssertNil(read(monitor))
        write("after resume", to: board)
        XCTAssertEqual(read(monitor), "after resume")
    }

    func testConfidentialTransientAndGeneratedMarkersAreConsumedWithoutReadingText() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        for marker in ClipboardMonitor.ignoredTypes {
            write("synthetic marked text", to: board, types: [marker])
            XCTAssertNil(read(monitor))
            XCTAssertNil(read(monitor))
        }
        write("ordinary text", to: board)
        XCTAssertEqual(read(monitor), "ordinary text")
    }

    func testOwnCopiesAreNotRecordedAndPreserveExactText() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        let text = "synthetic e\u{301}\0🙂"
        XCTAssertTrue(monitor.copyText(text))
        XCTAssertEqual(board.string(forType: .string), text)
        XCTAssertNil(read(monitor))
        write("a new external copy", to: board)
        XCTAssertEqual(read(monitor), "a new external copy")
    }

    func testOversizeInvalidAndEmptyTextAreSkippedWithoutReplacingClipboard() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        let huge = String(repeating: "x", count: HistoryStore.maximumTextBytes + 1)
        write(huge, to: board)
        XCTAssertNil(read(monitor))
        XCTAssertFalse(monitor.copyText(huge))
        XCTAssertEqual(board.string(forType: .string), huge)
        for data in [Data(), Data([0xff, 0xfe])] {
            let item = NSPasteboardItem()
            XCTAssertTrue(item.setData(data, forType: .string))
            board.clearContents()
            XCTAssertTrue(board.writeObjects([item]))
            XCTAssertNil(read(monitor))
        }
        let maximum = String(repeating: "🙂", count: HistoryStore.maximumTextBytes / 4)
        write(maximum, to: board)
        XCTAssertEqual(read(monitor), maximum)
    }

    func testFilesAndMultipleItemsAreNotSilentlyFlattenedToText() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        write("synthetic filename", to: board, types: [.fileURL])
        XCTAssertNil(read(monitor))
        let items = (0..<2).map { index in
            let item = NSPasteboardItem()
            item.setString("synthetic \(index)", forType: .string)
            return item
        }
        board.clearContents()
        XCTAssertTrue(board.writeObjects(items))
        XCTAssertNil(read(monitor))
    }

    func testExcludedAndUnknownSourcesDoNotBecomeDelayedCaptures() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        write("excluded copy", to: board)
        XCTAssertNil(read(monitor, exclusions: ["test.synthetic.app"]))
        XCTAssertNil(read(monitor))
        write("unknown source", to: board)
        XCTAssertNil(read(monitor, source: nil, exclusions: ["test.synthetic.app"]))
        XCTAssertNil(read(monitor))
        write("allowed copy", to: board)
        XCTAssertEqual(read(monitor, source: "test.allowed.app",
                            exclusions: ["test.synthetic.app"]), "allowed copy")
    }

    func testChangingPasteboardProviderDoesNotRecordMixedSnapshot() {
        let board = board()
        defer { board.releaseGlobally() }
        let monitor = ClipboardMonitor(pasteboard: board)
        monitor.setRecording(true)
        let provider = ChangingProvider(board: board)
        let item = NSPasteboardItem()
        item.setDataProvider(provider, forTypes: [.string])
        board.clearContents()
        XCTAssertTrue(board.writeObjects([item]))
        XCTAssertNil(read(monitor))
        // The replacement, if delivered by pboard synchronously, belongs to a later observation.
        XCTAssertGreaterThanOrEqual(provider.originalCount, 0)
        XCTAssertNotEqual(board.changeCount, provider.originalCount)
    }
}

private final class ChangingProvider: NSObject, NSPasteboardItemDataProvider {
    let board: NSPasteboard
    var originalCount = -1

    init(board: NSPasteboard) { self.board = board }

    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem,
                    provideDataForType type: NSPasteboard.PasteboardType) {
        originalCount = board.changeCount
        item.setString("synthetic old snapshot", forType: type)
        board.clearContents()
        board.setString("synthetic replacement", forType: .string)
    }
}

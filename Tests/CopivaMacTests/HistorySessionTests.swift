import AppKit
import CopivaCore
import XCTest
@testable import CopivaMac

@MainActor
final class HistorySessionTests: XCTestCase {
    func testFirstLaunchNeedsConsentAndPauseIsPersisted() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("copiva-session-tests-\(UUID().uuidString)")
        let suite = "copiva-session-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let board = NSPasteboard(name: .init(suite))
        defer {
            board.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        let session = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await session.open()
        XCTAssertTrue(session.isReady)
        XCTAssertFalse(session.isRecording)
        session.setRecording(true)
        XCTAssertFalse(session.isRecording)
        session.setRecording(true, consent: true)
        XCTAssertTrue(session.isRecording)
        XCTAssertTrue(defaults.bool(forKey: "captureConsent"))
        session.setRecording(false)
        XCTAssertFalse(defaults.bool(forKey: "recordingEnabled"))
        await session.close()
        let reopened = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await reopened.open()
        XCTAssertTrue(reopened.hasConsented)
        XCTAssertFalse(reopened.isRecording)
        await reopened.close()
    }

    func testExistingHistoryLoadsWhilePausedAndCopyDoesNotAddRows() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("copiva-session-tests-\(UUID().uuidString)")
        let suite = "copiva-session-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let board = NSPasteboard(name: .init(suite))
        defer {
            board.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        let store = try HistoryStore(directory: directory)
        let clip = try await store.record("synthetic saved copy")
        await store.close()
        let session = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await session.open()
        XCTAssertEqual(session.clips, [clip])
        XCTAssertTrue(session.copy(clip))
        XCTAssertEqual(board.string(forType: .string), clip.text)
        session.setRecording(true, consent: true)
        await session.pollOnce()
        XCTAssertEqual(session.clips, [clip])
        await session.changeLimit(100)
        XCTAssertEqual(session.historyLimit, 100)
        XCTAssertEqual(defaults.integer(forKey: "historyLimit"), 100)
        await session.clearHistory()
        XCTAssertTrue(session.clips.isEmpty)
        XCTAssertEqual(board.string(forType: .string), clip.text)
        await session.close()
    }

    func testCorruptStorageIsKeptAndCannotEnableCapture() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("copiva-session-tests-\(UUID().uuidString)")
        let suite = "copiva-session-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let board = NSPasteboard(name: .init(suite))
        defer {
            board.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("history.sqlite3")
        let bytes = Data("synthetic broken storage".utf8)
        try bytes.write(to: path)
        let session = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await session.open()
        XCTAssertFalse(session.isReady)
        XCTAssertNotNil(session.errorMessage)
        session.setRecording(true, consent: true)
        XCTAssertFalse(session.isRecording)
        XCTAssertEqual(try Data(contentsOf: path), bytes)
        await session.close()
    }
    func testCapturePersistsNewCopiesAndSuppressesOwnWritesAcrossSession() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("copiva-session-tests-\(UUID().uuidString)")
        let suite = "copiva-session-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let board = NSPasteboard(name: .init(suite))
        defer {
            board.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        board.clearContents()
        board.setString("synthetic before consent", forType: .string)
        let session = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await session.open()
        session.setRecording(true, consent: true)
        await session.pollOnce()
        XCTAssertTrue(session.clips.isEmpty)
        board.clearContents()
        board.setString("synthetic new copy", forType: .string)
        await session.pollOnce()
        let clip = try XCTUnwrap(session.clips.first)
        XCTAssertEqual(clip.text, "synthetic new copy")
        XCTAssertEqual(session.clips.count, 1)
        XCTAssertTrue(session.copy(clip))
        await session.pollOnce()
        XCTAssertEqual(session.clips, [clip])
        session.setRecording(false)
        board.clearContents()
        board.setString("synthetic paused copy", forType: .string)
        await session.pollOnce()
        XCTAssertEqual(session.clips, [clip])
        await session.close()
        let reopened = HistorySession(directory: directory, defaults: defaults, pasteboard: board)
        await reopened.open()
        XCTAssertEqual(reopened.clips, [clip])
        XCTAssertFalse(reopened.isRecording)
        await reopened.close()
    }

}

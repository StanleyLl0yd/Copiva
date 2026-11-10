import Foundation
import SQLite3
import XCTest
@testable import CopivaCore

@MainActor
final class HistoryStoreTests: XCTestCase {
    private func location() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("copiva-history-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private func sql(_ statement: String, in directory: URL) throws {
        var database: OpaquePointer?
        let path = directory.appendingPathComponent("history.sqlite3").path
        guard sqlite3_open(path, &database) == SQLITE_OK, let database else {
            if let database { sqlite3_close_v2(database) }
            throw HistoryError.storageUnavailable
        }
        defer { sqlite3_close_v2(database) }
        let result = sqlite3_exec(database, statement, nil, nil, nil)
        guard result == SQLITE_OK else { throw HistoryError.database(result) }
    }

    func testReopenPreservesUnicodeNullsDatesAndIdentity() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        let text = "Привет, café 👋\u{0}and more text"
        let original = try await store.record(text, copiedAt: Date(timeIntervalSince1970: 1234))
        await store.close()
        let reopened = try HistoryStore(directory: directory)
        let rows = try await reopened.search()
        XCTAssertEqual(rows, [original])
        let next = try await reopened.record("next")
        XCTAssertGreaterThan(next.id, original.id)
        await reopened.close()
    }

    func testSearchUsesUnicodePrefixesAndLiteralWords() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        let first = try await store.record("Café Привет alpha beta")
        let second = try await store.record("hello OR goodbye")
        let accent = try await store.search("cafe")
        let cyrillic = try await store.search("при")
        let operators = try await store.search("alpha OR beta")
        let literalOr = try await store.search("\" OR *")
        let punctuation = try await store.search("*")
        XCTAssertEqual(accent, [first])
        XCTAssertEqual(cyrillic, [first])
        XCTAssertTrue(operators.isEmpty)
        XCTAssertEqual(literalOr, [second])
        XCTAssertTrue(punctuation.isEmpty)
        await store.close()
    }

    func testRetentionRemovesOldRowsAndTheirSearchEntries() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory, limit: 2)
        _ = try await store.record("obsolete")
        let middle = try await store.record("middle")
        let latest = try await store.record("latest")
        let rows = try await store.search()
        let removed = try await store.search("obsolete")
        XCTAssertEqual(rows, [latest, middle])
        XCTAssertTrue(removed.isEmpty)
        try await store.setLimit(1)
        let reduced = try await store.search()
        XCTAssertEqual(reduced, [latest])
        do {
            try await store.setLimit(0)
            XCTFail("An invalid retention limit must not be accepted")
        } catch {
            XCTAssertEqual(error as? HistoryError, .invalidLimit)
        }
        let limit = await store.historyLimit
        let unchanged = try await store.search()
        XCTAssertEqual(limit, 1)
        XCTAssertEqual(unchanged, [latest])
        await store.close()
    }

    func testFailedCleanupRollsBackInsertionAndLimitChange() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory, limit: 2)
        let first = try await store.record("first")
        let second = try await store.record("second")
        try sql("""
            CREATE TRIGGER reject_cleanup BEFORE DELETE ON clips BEGIN
                SELECT RAISE(ABORT, 'synthetic cleanup failure');
            END;
            """, in: directory)
        do {
            _ = try await store.record("must not survive rollback")
            XCTFail("Failed pruning must roll back the whole insertion")
        } catch {
            XCTAssertEqual(error as? HistoryError, .database(SQLITE_CONSTRAINT))
        }
        do {
            try await store.setLimit(1)
            XCTFail("Failed pruning must not change the configured limit")
        } catch {
            XCTAssertEqual(error as? HistoryError, .database(SQLITE_CONSTRAINT))
        }
        let rows = try await store.search()
        let limit = await store.historyLimit
        XCTAssertEqual(rows, [second, first])
        XCTAssertEqual(limit, 2)
        try sql("DROP TRIGGER reject_cleanup", in: directory)
        let third = try await store.record("third")
        let afterRecovery = try await store.search()
        XCTAssertEqual(afterRecovery, [third, second])
        await store.close()
    }

    func testRejectsFutureSchemaWithoutReplacingHistory() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        _ = try await store.record("keep this history")
        await store.close()
        try sql("PRAGMA user_version = 2", in: directory)
        let path = directory.appendingPathComponent("history.sqlite3")
        let before = try Data(contentsOf: path)
        XCTAssertThrowsError(try HistoryStore(directory: directory)) {
            XCTAssertEqual($0 as? HistoryError, .unsupportedSchema(2))
        }
        XCTAssertEqual(try Data(contentsOf: path), before)
    }

    func testRejectsForeignUnversionedDatabaseWithoutChangingBytes() throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try sql("CREATE TABLE sqlitex_notes(text); INSERT INTO sqlitex_notes VALUES ('keep');",
                in: directory)
        let path = directory.appendingPathComponent("history.sqlite3")
        let before = try Data(contentsOf: path)
        XCTAssertThrowsError(try HistoryStore(directory: directory)) {
            XCTAssertEqual($0 as? HistoryError, .unrecognizedDatabase)
        }
        XCTAssertEqual(try Data(contentsOf: path), before)
    }

    func testCorruptDatabaseIsPreservedInsteadOfReset() throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("history.sqlite3")
        let bytes = Data("synthetic broken database".utf8)
        try bytes.write(to: path)
        XCTAssertThrowsError(try HistoryStore(directory: directory))
        XCTAssertEqual(try Data(contentsOf: path), bytes)
    }

    func testStorageIsPrivateAndDatabaseSymlinkIsRejected() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        let directoryMode = try FileManager.default.attributesOfItem(atPath: directory.path)
        let databaseURL = directory.appendingPathComponent("history.sqlite3")
        let databaseMode = try FileManager.default.attributesOfItem(atPath: databaseURL.path)
        XCTAssertEqual((directoryMode[.posixPermissions] as? NSNumber)?.intValue, 0o700)
        XCTAssertEqual((databaseMode[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        await store.close()
        try FileManager.default.removeItem(at: databaseURL)
        let target = directory.appendingPathComponent("untouched.txt")
        let bytes = Data("synthetic private file".utf8)
        try bytes.write(to: target)
        try FileManager.default.createSymbolicLink(at: databaseURL, withDestinationURL: target)
        XCTAssertThrowsError(try HistoryStore(directory: directory))
        XCTAssertEqual(try Data(contentsOf: target), bytes)
    }

    func testPayloadAndQueryBoundsDoNotDiscardExistingClips() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        let maximum = String(repeating: "🙂", count: HistoryStore.maximumTextBytes / 4)
        let clip = try await store.record(maximum)
        for invalid in ["", maximum + "🙂"] {
            do {
                _ = try await store.record(invalid)
                XCTFail("Invalid payload must be rejected")
            } catch {
                XCTAssertEqual(error as? HistoryError, .invalidText)
            }
        }
        do {
            _ = try await store.search(String(repeating: "a", count: 513))
            XCTFail("Oversized query must be rejected")
        } catch {
            XCTAssertEqual(error as? HistoryError, .invalidQuery)
        }
        do {
            _ = try await store.record("invalid date", copiedAt: Date(timeIntervalSince1970: .nan))
            XCTFail("Non-finite timestamps must be rejected")
        } catch {
            XCTAssertEqual(error as? HistoryError, .invalidTimestamp)
        }
        for invalidLimit in [0, Int.max] {
            do {
                _ = try await store.search(limit: invalidLimit)
                XCTFail("Invalid result limits must not reach SQLite")
            } catch {
                XCTAssertEqual(error as? HistoryError, .invalidLimit)
            }
        }
        let rows = try await store.search()
        XCTAssertEqual(rows, [clip])
        await store.close()
    }

    func testConcurrentWritersHaveUniqueStableOrdering() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask { _ = try await store.record("synthetic clip \(index)") }
            }
            try await group.waitForAll()
        }
        let rows = try await store.search()
        XCTAssertEqual(rows.count, 20)
        XCTAssertEqual(Set(rows.map(\.id)).count, 20)
        XCTAssertEqual(rows.map(\.id), rows.map(\.id).sorted(by: >))
        await store.close()
        do {
            _ = try await store.search()
            XCTFail("A closed connection must not be reused")
        } catch {
            XCTAssertEqual(error as? HistoryError, .closed)
        }
    }

    func testInvalidStoredTimestampFailsWithoutRewritingHistory() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        _ = try await store.record("preserve this record")
        await store.close()
        try sql("UPDATE clips SET copied_at = 'not a timestamp'", in: directory)
        let path = directory.appendingPathComponent("history.sqlite3")
        let before = try Data(contentsOf: path)
        let reopened = try HistoryStore(directory: directory)
        do {
            _ = try await reopened.search()
            XCTFail("Invalid storage must not be silently coerced to a different date")
        } catch {
            XCTAssertEqual(error as? HistoryError, .unrecognizedDatabase)
        }
        await reopened.close()
        XCTAssertEqual(try Data(contentsOf: path), before)
    }

    func testDirectorySymlinkDoesNotChangeItsTarget() throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let real = directory.appendingPathComponent("real")
        let alias = directory.appendingPathComponent("alias")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], atPath: real.path)
        let target = real.appendingPathComponent("history.sqlite3")
        let bytes = Data("synthetic untouched file".utf8)
        try bytes.write(to: target)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: real)
        XCTAssertThrowsError(try HistoryStore(directory: alias))
        XCTAssertEqual(try Data(contentsOf: target), bytes)
        let attributes = try FileManager.default.attributesOfItem(atPath: real.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o755)
    }

    func testExplicitDeletionAndClearKeepIndexAndIdentifiersConsistent() async throws {
        let directory = location()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try HistoryStore(directory: directory)
        let first = try await store.record("erasable")
        let second = try await store.record("retained")
        let removed = try await store.remove(id: first.id)
        let removedTwice = try await store.remove(id: first.id)
        let matches = try await store.search("erasable")
        XCTAssertTrue(removed)
        XCTAssertFalse(removedTwice)
        XCTAssertTrue(matches.isEmpty)
        try sql("""
            CREATE TRIGGER reject_clear BEFORE DELETE ON clips BEGIN
                SELECT RAISE(FAIL, 'synthetic clear failure');
            END;
            """, in: directory)
        do {
            try await store.clearOrdinaryHistory()
            XCTFail("Failed clear must roll back")
        } catch {
            XCTAssertEqual(error as? HistoryError, .database(SQLITE_CONSTRAINT))
        }
        let unchanged = try await store.search()
        XCTAssertEqual(unchanged, [second])
        try sql("DROP TRIGGER reject_clear", in: directory)
        try await store.clearOrdinaryHistory()
        let empty = try await store.search()
        let oldMatches = try await store.search("retained")
        XCTAssertTrue(empty.isEmpty)
        XCTAssertTrue(oldMatches.isEmpty)
        let next = try await store.record("after clearing")
        XCTAssertGreaterThan(next.id, second.id)
        await store.close()
    }
}

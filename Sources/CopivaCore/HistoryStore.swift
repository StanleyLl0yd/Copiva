import Foundation
import SQLite3

public struct TextClip: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let text: String
    public let copiedAt: Date
}

public enum HistoryError: Error, Equatable, Sendable {
    case invalidLocation
    case storageUnavailable
    case invalidText
    case invalidTimestamp
    case invalidLimit
    case invalidQuery
    case unrecognizedDatabase
    case unsupportedSchema(Int64)
    case closed
    case database(Int32)
}

/// Owns a database in a directory dedicated to Copiva history.
public actor HistoryStore {
    public static let maximumTextBytes = 256 * 1024
    public static let maximumHistoryCount = 10_000
    public static let maximumResultCount = 200

    private let connection: HistoryConnection
    public private(set) var historyLimit: Int

    public init(directory: URL, limit: Int = 500) throws {
        guard (1...Self.maximumHistoryCount).contains(limit) else {
            throw HistoryError.invalidLimit
        }
        guard directory.isFileURL, !directory.path.utf8.contains(0) else {
            throw HistoryError.invalidLocation
        }
        let manager = FileManager.default
        let url = directory.appendingPathComponent("history.sqlite3")
        do {
            if let existing = try? manager.attributesOfItem(atPath: directory.path),
               existing[.type] as? FileAttributeType != .typeDirectory {
                throw HistoryError.invalidLocation
            }
            try manager.createDirectory(at: directory, withIntermediateDirectories: true,
                                        attributes: [.posixPermissions: 0o700])
            let attributes = try manager.attributesOfItem(atPath: directory.path)
            guard attributes[.type] as? FileAttributeType == .typeDirectory else {
                throw HistoryError.invalidLocation
            }
            try manager.setAttributes([.posixPermissions: 0o700], atPath: directory.path)
            if manager.fileExists(atPath: url.path) {
                let attributes = try manager.attributesOfItem(atPath: url.path)
                guard attributes[.type] as? FileAttributeType == .typeRegular else {
                    throw HistoryError.invalidLocation
                }
            }
        } catch let error as HistoryError {
            throw error
        } catch {
            throw HistoryError.storageUnavailable
        }
        let connection = try HistoryConnection(url: url)
        do {
            try manager.setAttributes([.posixPermissions: 0o600], atPath: url.path)
        } catch {
            throw HistoryError.storageUnavailable
        }
        try connection.initializeSchema()
        self.connection = connection
        self.historyLimit = limit
    }

    public func record(_ text: String, copiedAt: Date = Date()) throws -> TextClip {
        guard !text.isEmpty, text.utf8.count <= Self.maximumTextBytes else {
            throw HistoryError.invalidText
        }
        let timestamp = copiedAt.timeIntervalSince1970
        guard timestamp.isFinite else {
            throw HistoryError.invalidTimestamp
        }
        return try connection.transaction {
            let id = try connection.statement(
                "INSERT INTO clips(text, copied_at) VALUES (?, ?)") { statement, database in
                try HistoryConnection.bind(text, to: 1, in: statement)
                try HistoryConnection.check(sqlite3_bind_double(
                    statement, 2, timestamp))
                try HistoryConnection.check(sqlite3_step(statement), expecting: SQLITE_DONE)
                return sqlite3_last_insert_rowid(database)
            }
            try connection.prune(to: historyLimit)
            return TextClip(id: id, text: text, copiedAt: Date(timeIntervalSince1970: timestamp))
        }
    }

    /// Searches word prefixes, treating user text as words rather than FTS operators.
    public func search(_ query: String = "", limit: Int = 100) throws -> [TextClip] {
        guard (1...Self.maximumResultCount).contains(limit) else {
            throw HistoryError.invalidLimit
        }
        guard query.utf8.count <= 512 else { throw HistoryError.invalidQuery }
        let words = query.split { !$0.isLetter && !$0.isNumber }
        guard words.count <= 32 else { throw HistoryError.invalidQuery }
        if words.isEmpty && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        let hasQuery = !words.isEmpty
        let sql = hasQuery
            ? """
              SELECT clips.id, clips.text, clips.copied_at FROM clips
              JOIN clips_fts ON clips_fts.rowid = clips.id
              WHERE clips_fts MATCH ? ORDER BY clips.id DESC LIMIT ?
              """
            : "SELECT id, text, copied_at FROM clips ORDER BY id DESC LIMIT ?"
        return try connection.statement(sql) { statement, _ in
            if hasQuery {
                let literal = words.map { "\"\($0)\"*" }.joined(separator: " AND ")
                try HistoryConnection.bind(literal, to: 1, in: statement)
            }
            try HistoryConnection.check(sqlite3_bind_int(
                statement, hasQuery ? 2 : 1, Int32(limit)))
            var clips: [TextClip] = []
            while true {
                let result = sqlite3_step(statement)
                if result == SQLITE_DONE { return clips }
                try HistoryConnection.check(result, expecting: SQLITE_ROW)
                // Inspect storage classes before column accessors can convert their values.
                let timestampType = sqlite3_column_type(statement, 2)
                guard sqlite3_column_type(statement, 0) == SQLITE_INTEGER,
                      sqlite3_column_type(statement, 1) == SQLITE_TEXT,
                      timestampType == SQLITE_FLOAT || timestampType == SQLITE_INTEGER else {
                    throw HistoryError.unrecognizedDatabase
                }
                let id = sqlite3_column_int64(statement, 0)
                let timestamp = sqlite3_column_double(statement, 2)
                guard id > 0, timestamp.isFinite else {
                    throw HistoryError.unrecognizedDatabase
                }
                let size = Int(sqlite3_column_bytes(statement, 1))
                guard size > 0, size <= Self.maximumTextBytes,
                      let bytes = sqlite3_column_text(statement, 1),
                      let text = String(bytes: UnsafeBufferPointer(
                        start: bytes, count: size),
                                        encoding: .utf8) else {
                    throw HistoryError.invalidText
                }
                clips.append(TextClip(
                    id: id, text: text,
                    copiedAt: Date(timeIntervalSince1970: timestamp)))
            }
        }
    }

    public func setLimit(_ limit: Int) throws {
        guard (1...Self.maximumHistoryCount).contains(limit) else {
            throw HistoryError.invalidLimit
        }
        try connection.transaction { try connection.prune(to: limit) }
        historyLimit = limit
    }

    @discardableResult
    public func remove(id: Int64) throws -> Bool {
        try connection.transaction {
            try connection.statement("DELETE FROM clips WHERE id = ?") { statement, database in
                try HistoryConnection.check(sqlite3_bind_int64(statement, 1, id))
                try HistoryConnection.check(sqlite3_step(statement), expecting: SQLITE_DONE)
                return sqlite3_changes(database) > 0
            }
        }
    }

    public func clearOrdinaryHistory() throws {
        try connection.transaction {
            try connection.statement("DELETE FROM clips") { statement, _ in
                try HistoryConnection.check(sqlite3_step(statement), expecting: SQLITE_DONE)
            }
        }
    }

    public func close() { connection.close() }
}

// The actor exclusively owns this connection; this object also closes failed initializations.
private final class HistoryConnection {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        var database: OpaquePointer?
        let result = sqlite3_open_v2(url.path, &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
                | SQLITE_OPEN_NOFOLLOW, nil)
        guard result == SQLITE_OK, let database else {
            if let database { sqlite3_close_v2(database) }
            throw HistoryError.database(result)
        }
        handle = database
        sqlite3_busy_timeout(database, 5_000)
    }

    deinit {
        if let handle { sqlite3_close_v2(handle) }
    }

    func close() {
        if let handle { sqlite3_close_v2(handle) }
        handle = nil
    }

    static func check(_ result: Int32, expecting expected: Int32 = SQLITE_OK) throws {
        guard result == expected else { throw HistoryError.database(result) }
    }

    func statement<T>(_ sql: String, _ body: (OpaquePointer, OpaquePointer) throws -> T) throws -> T {
        guard let handle else { throw HistoryError.closed }
        var prepared: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &prepared, nil)
        guard result == SQLITE_OK, let prepared else {
            if let prepared { sqlite3_finalize(prepared) }
            throw HistoryError.database(result)
        }
        defer { sqlite3_finalize(prepared) }
        return try body(prepared, handle)
    }

    static func bind(_ text: String, to index: Int32, in statement: OpaquePointer) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let result = text.utf8CString.withUnsafeBufferPointer { bytes in
            sqlite3_bind_text(statement, index, bytes.baseAddress, Int32(bytes.count - 1), transient)
        }
        try check(result)
    }

    private func execute(_ sql: String) throws {
        guard let handle else { throw HistoryError.closed }
        try Self.check(sqlite3_exec(handle, sql, nil, nil, nil))
    }

    private func integer(_ sql: String) throws -> Int64 {
        try statement(sql) { statement, _ in
            try Self.check(sqlite3_step(statement), expecting: SQLITE_ROW)
            return sqlite3_column_int64(statement, 0)
        }
    }

    func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let result = try body()
            try execute("COMMIT")
            return result
        } catch {
            do { try execute("ROLLBACK") }
            catch { close() }
            throw error
        }
    }

    func prune(to limit: Int) throws {
        try statement("""
            DELETE FROM clips WHERE id NOT IN (
                SELECT id FROM clips ORDER BY id DESC LIMIT ?)
            """) { statement, _ in
            try Self.check(sqlite3_bind_int(statement, 1, Int32(limit)))
            try Self.check(sqlite3_step(statement), expecting: SQLITE_DONE)
        }
    }

    func initializeSchema() throws {
        let version = try integer("PRAGMA user_version")
        guard version == 0 || version == 1 else {
            throw HistoryError.unsupportedSchema(version)
        }
        let application = try integer("PRAGMA application_id")
        if version == 0 {
            let objects = try integer(
                "SELECT count(*) FROM sqlite_master WHERE name NOT GLOB 'sqlite_*'")
            guard objects == 0, application == 0 else {
                throw HistoryError.unrecognizedDatabase
            }
        } else {
            guard application == 0x43505641 else { throw HistoryError.unrecognizedDatabase }
            let objects = try integer("""
                SELECT count(*) FROM sqlite_master
                WHERE (type = 'table' AND name IN ('clips', 'clips_fts'))
                   OR (type = 'trigger' AND name IN ('clips_insert', 'clips_delete'))
                """)
            guard objects == 4 else { throw HistoryError.unrecognizedDatabase }
            try statement("SELECT id, text, copied_at FROM clips LIMIT 0") { _, _ in }
            try statement("SELECT rowid FROM clips_fts LIMIT 0") { _, _ in }
        }
        let mode = try statement("PRAGMA journal_mode=WAL") { statement, _ in
            try Self.check(sqlite3_step(statement), expecting: SQLITE_ROW)
            return sqlite3_column_text(statement, 0).map { String(cString: $0) }
        }
        guard mode == "wal" else { throw HistoryError.storageUnavailable }
        try execute("PRAGMA synchronous=FULL")
        try execute("PRAGMA secure_delete=ON")
        if version == 0 {
            try transaction {
                try execute("""
                    CREATE TABLE clips (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        text TEXT NOT NULL,
                        copied_at REAL NOT NULL
                    );
                    CREATE VIRTUAL TABLE clips_fts USING fts5(
                        text, content='clips', content_rowid='id',
                        tokenize='unicode61 remove_diacritics 2'
                    );
                    CREATE TRIGGER clips_insert AFTER INSERT ON clips BEGIN
                        INSERT INTO clips_fts(rowid, text) VALUES (new.id, new.text);
                    END;
                    CREATE TRIGGER clips_delete AFTER DELETE ON clips BEGIN
                        INSERT INTO clips_fts(clips_fts, rowid, text)
                            VALUES ('delete', old.id, old.text);
                    END;
                    PRAGMA application_id = 1129338433;
                    PRAGMA user_version = 1;
                    """)
            }
        }
    }
}

import Foundation
import SQLite3

// SQLITE_TRANSIENT tells SQLite to copy the string before bind returns.
// The C macro is not imported into Swift, so we define it here.
private let SQLITE_TRANSIENT = unsafeBitCast(-1 as Int, to: sqlite3_destructor_type.self)

public final class BibleDatabase {
    private var db: OpaquePointer?

    public init(bundle: Bundle = .main) {
        guard let dbPath = bundle.path(forResource: "kjv", ofType: "sqlite") else {
            print("BibleDatabase: kjv.sqlite not found in bundle")
            return
        }
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(dbPath, &db, flags, nil) != SQLITE_OK {
            print("BibleDatabase: Failed to open — \(String(cString: sqlite3_errmsg(db)))")
            db = nil
        }
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Single Verse Lookup

    public func verse(bookName: String, chapter: Int, verse: Int) -> Verse? {
        let sql = """
            SELECT v.id, v.number, v.text, c.number, b.name
            FROM verses v
            JOIN chapters c ON v.chapter_id = c.id
            JOIN books b ON c.book_id = b.id
            WHERE lower(b.name) = lower(?) AND c.number = ? AND v.number = ?
            LIMIT 1
            """
        return queryVerses(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, bookName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(chapter))
            sqlite3_bind_int(stmt, 3, Int32(verse))
        }).first
    }

    // MARK: - All Books

    public func allBooks() -> [Book] {
        guard db != nil else { return [] }
        let sql = "SELECT id, name, testament, abbreviation FROM books ORDER BY id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var books: [Book] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            books.append(Book(
                id: Int(sqlite3_column_int(stmt, 0)),
                name: String(cString: sqlite3_column_text(stmt, 1)),
                testament: String(cString: sqlite3_column_text(stmt, 2)),
                abbreviation: String(cString: sqlite3_column_text(stmt, 3))
            ))
        }
        return books
    }

    // MARK: - Chapter Count

    public func chapterCount(bookName: String) -> Int {
        guard db != nil else { return 0 }
        let sql = """
            SELECT COUNT(c.id) FROM chapters c
            JOIN books b ON c.book_id = b.id
            WHERE lower(b.name) = lower(?)
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookName, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    // MARK: - Verse Range Lookup

    /// Returns verses for a chapter range from `from` to `through` (inclusive).
    public func verses(bookName: String, chapter: Int, from startVerse: Int, through endVerse: Int) -> [Verse] {
        let sql = """
            SELECT v.id, v.number, v.text, c.number, b.name
            FROM verses v
            JOIN chapters c ON v.chapter_id = c.id
            JOIN books b ON c.book_id = b.id
            WHERE lower(b.name) = lower(?) AND c.number = ? AND v.number >= ? AND v.number <= ?
            ORDER BY v.number
            """
        return queryVerses(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, bookName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(chapter))
            sqlite3_bind_int(stmt, 3, Int32(startVerse))
            sqlite3_bind_int(stmt, 4, Int32(endVerse))
        })
    }

    // MARK: - Verses in Chapter

    public func verses(bookName: String, chapter: Int) -> [Verse] {
        let sql = """
            SELECT v.id, v.number, v.text, c.number, b.name
            FROM verses v
            JOIN chapters c ON v.chapter_id = c.id
            JOIN books b ON c.book_id = b.id
            WHERE lower(b.name) = lower(?) AND c.number = ?
            ORDER BY v.number
            """
        return queryVerses(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, bookName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(chapter))
        })
    }

    // MARK: - FTS5 Keyword Search

    public func search(query: String, limit: Int = 50) -> [Verse] {
        guard db != nil, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let sql = """
            SELECT v.id, v.number, v.text, c.number, b.name
            FROM verses_fts
            JOIN verses v ON verses_fts.rowid = v.id
            JOIN chapters c ON v.chapter_id = c.id
            JOIN books b ON c.book_id = b.id
            WHERE verses_fts MATCH ?
            ORDER BY rank
            LIMIT ?
            """
        // Build an FTS5 query: each word gets a prefix wildcard for partial matching.
        // Single token: "grace*", multi-token: "love* is* patient*"
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let ftsQuery = trimmed
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0 + "*" }
            .joined(separator: " ")
        return queryVerses(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, ftsQuery, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(limit))
        })
    }

    // MARK: - Verse by ID

    public func verse(id: Int) -> Verse? {
        let sql = """
            SELECT v.id, v.number, v.text, c.number, b.name
            FROM verses v
            JOIN chapters c ON v.chapter_id = c.id
            JOIN books b ON c.book_id = b.id
            WHERE v.id = ?
            LIMIT 1
            """
        return queryVerses(sql: sql, bind: { stmt in
            sqlite3_bind_int(stmt, 1, Int32(id))
        }).first
    }

    // MARK: - Private Helpers

    /// Columns expected: 0=v.id, 1=v.number, 2=v.text, 3=chapter_number, 4=book_name
    private func queryVerses(sql: String, bind: (OpaquePointer) -> Void) -> [Verse] {
        guard db != nil else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        bind(stmt!)

        var results: [Verse] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(Verse(
                id: Int(sqlite3_column_int(stmt, 0)),
                bookName: String(cString: sqlite3_column_text(stmt, 4)),
                chapterNumber: Int(sqlite3_column_int(stmt, 3)),
                verseNumber: Int(sqlite3_column_int(stmt, 1)),
                text: String(cString: sqlite3_column_text(stmt, 2))
            ))
        }
        return results
    }
}

import Foundation

/// Thin wrapper around BibleDatabase.search — prepared for async/pagination in future cards.
public final class SearchService {
    private let database: BibleDatabase

    public init(database: BibleDatabase = BibleDatabase()) {
        self.database = database
    }

    /// Full-text keyword search using FTS5. Returns up to `limit` results.
    public func search(query: String, limit: Int = 50) -> [Verse] {
        database.search(query: query, limit: limit)
    }
}

import Foundation

/// In-memory + UserDefaults cache for API-fetched Bible verses.
/// Reduces redundant API calls for ESV and NLT translations.
///
/// Cache strategy:
/// - In-memory dictionary for fast access during the session.
/// - UserDefaults persistence for cross-session caching.
/// - TTL: 24 hours (verse content doesn't change).
/// - Max 500 verses per translation to respect licensing.
public final class VerseCache: @unchecked Sendable {

    public static let shared = VerseCache()

    // MARK: - Configuration

    private let ttlSeconds: TimeInterval = 24 * 60 * 60  // 24 hours
    private let maxVersesPerTranslation = 500
    private let userDefaultsPrefix = "VerseCache_"

    // MARK: - In-Memory Storage

    private var memoryCache: [String: CachedEntry] = [:]
    private let lock = NSLock()

    // MARK: - Types

    private struct CachedEntry: Codable {
        let verses: [CachedVerse]
        let timestamp: Date
    }

    private struct CachedVerse: Codable {
        let id: Int
        let bookName: String
        let chapterNumber: Int
        let verseNumber: Int
        let text: String
        let translation: String
    }

    // MARK: - Public API

    /// Retrieve cached verses for a chapter lookup.
    /// Returns nil if not cached or cache has expired.
    public func verses(translation: String, book: String, chapter: Int) -> [Verse]? {
        let key = cacheKey(translation: translation, book: book, chapter: chapter)
        return get(key: key)
    }

    /// Store verses from a chapter lookup in the cache.
    public func store(verses: [Verse], translation: String, book: String, chapter: Int) {
        let key = cacheKey(translation: translation, book: book, chapter: chapter)
        set(key: key, verses: verses)
        enforceLimit(translation: translation)
    }

    /// Retrieve cached verses for a verse range lookup.
    public func verseRange(translation: String, book: String, chapter: Int, from: Int, through: Int) -> [Verse]? {
        let key = rangeKey(translation: translation, book: book, chapter: chapter, from: from, through: through)
        return get(key: key)
    }

    /// Store verses from a range lookup in the cache.
    public func storeRange(verses: [Verse], translation: String, book: String, chapter: Int, from: Int, through: Int) {
        let key = rangeKey(translation: translation, book: book, chapter: chapter, from: from, through: through)
        set(key: key, verses: verses)
        enforceLimit(translation: translation)
    }

    /// Retrieve a cached single verse.
    public func verse(translation: String, book: String, chapter: Int, verse: Int) -> Verse? {
        let key = singleKey(translation: translation, book: book, chapter: chapter, verse: verse)
        return get(key: key)?.first
    }

    /// Store a single verse in the cache.
    public func store(verse: Verse, translation: String, book: String, chapter: Int, verseNum: Int) {
        let key = singleKey(translation: translation, book: book, chapter: chapter, verse: verseNum)
        set(key: key, verses: [verse])
        enforceLimit(translation: translation)
    }

    /// Retrieve cached search results.
    public func searchResults(translation: String, query: String) -> [Verse]? {
        let key = searchKey(translation: translation, query: query)
        return get(key: key)
    }

    /// Store search results in the cache.
    public func storeSearchResults(verses: [Verse], translation: String, query: String) {
        let key = searchKey(translation: translation, query: query)
        set(key: key, verses: verses)
        enforceLimit(translation: translation)
    }

    /// Clear all cached data for a specific translation.
    public func clear(translation: String) {
        lock.lock()
        defer { lock.unlock() }

        let prefix = "\(translation)_"
        let keysToRemove = memoryCache.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
        }
    }

    /// Clear all cached data.
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        for key in memoryCache.keys {
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
        }
        memoryCache.removeAll()
    }

    // MARK: - Private Helpers

    private func cacheKey(translation: String, book: String, chapter: Int) -> String {
        "\(translation)_\(book)_\(chapter)"
    }

    private func rangeKey(translation: String, book: String, chapter: Int, from: Int, through: Int) -> String {
        "\(translation)_\(book)_\(chapter)_\(from)-\(through)"
    }

    private func singleKey(translation: String, book: String, chapter: Int, verse: Int) -> String {
        "\(translation)_\(book)_\(chapter)_v\(verse)"
    }

    private func searchKey(translation: String, query: String) -> String {
        "\(translation)_search_\(query.lowercased())"
    }

    private func get(key: String) -> [Verse]? {
        lock.lock()
        defer { lock.unlock() }

        // Try memory cache first
        if let entry = memoryCache[key] {
            if Date().timeIntervalSince(entry.timestamp) < ttlSeconds {
                return entry.verses.map { toVerse($0) }
            } else {
                memoryCache.removeValue(forKey: key)
                UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
                return nil
            }
        }

        // Try UserDefaults
        guard let data = UserDefaults.standard.data(forKey: userDefaultsPrefix + key),
              let entry = try? JSONDecoder().decode(CachedEntry.self, from: data)
        else { return nil }

        if Date().timeIntervalSince(entry.timestamp) < ttlSeconds {
            memoryCache[key] = entry
            return entry.verses.map { toVerse($0) }
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
            return nil
        }
    }

    private func set(key: String, verses: [Verse]) {
        lock.lock()
        defer { lock.unlock() }

        let cached = verses.map { toCached($0) }
        let entry = CachedEntry(verses: cached, timestamp: Date())
        memoryCache[key] = entry

        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: userDefaultsPrefix + key)
        }
    }

    /// Enforce the per-translation verse limit by evicting oldest entries.
    private func enforceLimit(translation: String) {
        let prefix = "\(translation)_"
        let translationKeys = memoryCache.keys.filter { $0.hasPrefix(prefix) }

        var totalVerses = 0
        for key in translationKeys {
            totalVerses += memoryCache[key]?.verses.count ?? 0
        }

        if totalVerses > maxVersesPerTranslation {
            // Sort by timestamp (oldest first) and remove until under limit
            let sorted = translationKeys
                .compactMap { key -> (String, Date)? in
                    guard let entry = memoryCache[key] else { return nil }
                    return (key, entry.timestamp)
                }
                .sorted { $0.1 < $1.1 }

            var remaining = totalVerses
            for (key, _) in sorted {
                guard remaining > maxVersesPerTranslation else { break }
                let count = memoryCache[key]?.verses.count ?? 0
                memoryCache.removeValue(forKey: key)
                UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
                remaining -= count
            }
        }
    }

    // MARK: - Conversion

    private func toCached(_ verse: Verse) -> CachedVerse {
        CachedVerse(
            id: verse.id,
            bookName: verse.bookName,
            chapterNumber: verse.chapterNumber,
            verseNumber: verse.verseNumber,
            text: verse.text,
            translation: verse.translation
        )
    }

    private func toVerse(_ cached: CachedVerse) -> Verse {
        Verse(
            id: cached.id,
            bookName: cached.bookName,
            chapterNumber: cached.chapterNumber,
            verseNumber: cached.verseNumber,
            text: cached.text,
            translation: cached.translation
        )
    }
}

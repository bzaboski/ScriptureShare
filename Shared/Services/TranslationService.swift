import Foundation

/// Errors from the translation routing layer.
public enum TranslationServiceError: LocalizedError {
    case translationNotAvailable(Translation)
    case offline(Translation)
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .translationNotAvailable(let t):
            return "\(t.displayName) is not available. Configure the API key in Settings."
        case .offline(let t):
            return "No internet connection. Switch to KJV for offline access."
        case .underlying(let error):
            return error.localizedDescription
        }
    }

    /// Whether this error is a network/offline issue.
    public var isOffline: Bool {
        switch self {
        case .offline: return true
        case .underlying(let error):
            return (error as NSError).domain == NSURLErrorDomain
        default: return false
        }
    }
}

/// Unified translation service that routes verse lookups to the correct data source.
/// KJV uses the local SQLite database; ESV and NLT use their respective API services.
public final class TranslationService: @unchecked Sendable {

    public static let shared = TranslationService()

    private let database: BibleDatabase
    private let esvService: ESVService
    private let nltService: NLTService
    private let cache: VerseCache
    private let popularCache: PopularVerseCache

    public init(
        database: BibleDatabase = BibleDatabase(),
        esvService: ESVService = ESVService(),
        nltService: NLTService = NLTService(),
        cache: VerseCache = .shared,
        popularCache: PopularVerseCache = .shared
    ) {
        self.database = database
        self.esvService = esvService
        self.nltService = nltService
        self.cache = cache
        self.popularCache = popularCache
        self.popularCache.loadIfNeeded()
    }

    // MARK: - Single Verse

    /// Fetch a single verse from the appropriate source.
    public func verse(book: String, chapter: Int, verse: Int, translation: Translation) async throws -> Verse? {
        switch translation {
        case .kjv:
            return database.verse(bookName: book, chapter: chapter, verse: verse)

        case .esv, .nlt:
            guard translation.isAvailable else {
                throw TranslationServiceError.translationNotAvailable(translation)
            }
            // 1. Check popular verse cache (bundled, instant, no API call)
            if let popular = popularCache.verses(book: book, chapter: chapter, verse: verse, translation: translation),
               let match = popular.first {
                return match
            }
            // 2. Check runtime cache
            if let cached = cache.verse(translation: translation.rawValue, book: book, chapter: chapter, verse: verse) {
                return cached
            }
            // 3. Fetch from API
            do {
                let service = translation == .esv ? esvService : nil
                let result: Verse
                if let esv = service {
                    result = try await esv.fetchVerse(book: book, chapter: chapter, verse: verse)
                } else {
                    result = try await nltService.fetchVerse(book: book, chapter: chapter, verse: verse)
                }
                cache.store(verse: result, translation: translation.rawValue, book: book, chapter: chapter, verseNum: verse)
                return result
            } catch {
                throw mapError(error, translation: translation)
            }
        }
    }

    // MARK: - Chapter Verses

    /// Fetch all verses in a chapter from the appropriate source.
    public func verses(book: String, chapter: Int, translation: Translation) async throws -> [Verse] {
        switch translation {
        case .kjv:
            return database.verses(bookName: book, chapter: chapter)

        case .esv, .nlt:
            guard translation.isAvailable else {
                throw TranslationServiceError.translationNotAvailable(translation)
            }
            if let cached = cache.verses(translation: translation.rawValue, book: book, chapter: chapter) {
                return cached
            }
            do {
                let results: [Verse]
                if translation == .esv {
                    results = try await esvService.fetchVerses(book: book, chapter: chapter)
                } else {
                    results = try await nltService.fetchVerses(book: book, chapter: chapter)
                }
                cache.store(verses: results, translation: translation.rawValue, book: book, chapter: chapter)
                return results
            } catch {
                throw mapError(error, translation: translation)
            }
        }
    }

    // MARK: - Verse Range

    /// Fetch a range of verses within a chapter.
    public func verseRange(book: String, chapter: Int, from startVerse: Int, through endVerse: Int, translation: Translation) async throws -> [Verse] {
        switch translation {
        case .kjv:
            return database.verses(bookName: book, chapter: chapter, from: startVerse, through: endVerse)

        case .esv, .nlt:
            guard translation.isAvailable else {
                throw TranslationServiceError.translationNotAvailable(translation)
            }
            // Check popular cache for ranges (e.g. Psalm 23:1-6)
            if let popular = popularCache.verses(book: book, chapter: chapter, verse: startVerse, endVerse: endVerse, translation: translation),
               !popular.isEmpty {
                return popular
            }
            if let cached = cache.verseRange(translation: translation.rawValue, book: book, chapter: chapter, from: startVerse, through: endVerse) {
                return cached
            }
            do {
                let results: [Verse]
                if translation == .esv {
                    results = try await esvService.fetchVerseRange(book: book, chapter: chapter, from: startVerse, through: endVerse)
                } else {
                    results = try await nltService.fetchVerseRange(book: book, chapter: chapter, from: startVerse, through: endVerse)
                }
                cache.storeRange(verses: results, translation: translation.rawValue, book: book, chapter: chapter, from: startVerse, through: endVerse)
                return results
            } catch {
                throw mapError(error, translation: translation)
            }
        }
    }

    // MARK: - Search

    /// Search verses across the selected translation.
    public func search(query: String, translation: Translation, limit: Int = 50) async throws -> [Verse] {
        switch translation {
        case .kjv:
            return database.search(query: query, limit: limit)

        case .esv, .nlt:
            guard translation.isAvailable else {
                throw TranslationServiceError.translationNotAvailable(translation)
            }
            if let cached = cache.searchResults(translation: translation.rawValue, query: query) {
                return cached
            }
            do {
                let results: [Verse]
                if translation == .esv {
                    results = try await esvService.search(query: query, limit: limit)
                } else {
                    results = try await nltService.search(query: query, limit: limit)
                }
                cache.storeSearchResults(verses: results, translation: translation.rawValue, query: query)
                return results
            } catch {
                throw mapError(error, translation: translation)
            }
        }
    }

    // MARK: - Book List

    /// All 66 books of the Bible. All translations share the same canonical book list.
    public func allBooks(translation: Translation) -> [Book] {
        // The canonical book list is the same for all translations.
        // We use the KJV database as the source of truth for book metadata.
        database.allBooks()
    }

    // MARK: - Chapter Count

    /// Get the number of chapters in a book. Same across all translations.
    public func chapterCount(bookName: String) -> Int {
        database.chapterCount(bookName: bookName)
    }

    // MARK: - Verse by ID (KJV only)

    /// Look up a verse by its SQLite row ID. Only works for KJV.
    public func verse(id: Int) -> Verse? {
        database.verse(id: id)
    }

    // MARK: - Error Mapping

    /// Map service-specific errors to TranslationServiceError.
    private func mapError(_ error: Error, translation: Translation) -> TranslationServiceError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return .offline(translation)
            default:
                return .underlying(error)
            }
        }

        if let esvError = error as? ESVServiceError {
            if case .networkError(let inner) = esvError,
               let urlError = inner as? URLError,
               [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code) {
                return .offline(translation)
            }
            return .underlying(error)
        }

        if let nltError = error as? NLTServiceError {
            if case .networkError(let inner) = nltError,
               let urlError = inner as? URLError,
               [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code) {
                return .offline(translation)
            }
            return .underlying(error)
        }

        return .underlying(error)
    }
}

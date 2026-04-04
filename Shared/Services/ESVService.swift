import Foundation

/// Errors specific to ESV API interactions.
public enum ESVServiceError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)
    case decodingError(Error)
    case noPassageFound

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "ESV API key not configured. Add your key in APIConfig.swift."
        case .invalidURL:
            return "Invalid ESV API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "ESV API returned status \(code)."
        case .decodingError(let error):
            return "Failed to parse ESV response: \(error.localizedDescription)"
        case .noPassageFound:
            return "No passage found for the given reference."
        }
    }
}

/// Fetches Bible verses from the ESV API (https://api.esv.org/).
/// All methods are async and require a valid API key in APIConfig.
public final class ESVService: Sendable {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Fetch a single verse by book, chapter, and verse number.
    public func fetchVerse(book: String, chapter: Int, verse: Int) async throws -> Verse {
        let query = "\(book)+\(chapter):\(verse)"
        let passages = try await fetchPassage(query: query)
        guard let text = passages.first, !text.isEmpty else {
            throw ESVServiceError.noPassageFound
        }
        let cleaned = cleanVerseText(text)
        return Verse(
            id: syntheticID(book: book, chapter: chapter, verse: verse),
            bookName: book,
            chapterNumber: chapter,
            verseNumber: verse,
            text: cleaned,
            translation: "ESV"
        )
    }

    /// Fetch all verses in a chapter.
    public func fetchVerses(book: String, chapter: Int) async throws -> [Verse] {
        let query = "\(book)+\(chapter)"
        let passages = try await fetchPassage(query: query, includeVerseNumbers: true)
        guard let fullText = passages.first, !fullText.isEmpty else {
            throw ESVServiceError.noPassageFound
        }
        return parseNumberedVerses(fullText, book: book, chapter: chapter)
    }

    /// Fetch a range of verses within a chapter.
    public func fetchVerseRange(book: String, chapter: Int, from startVerse: Int, through endVerse: Int) async throws -> [Verse] {
        let query = "\(book)+\(chapter):\(startVerse)-\(endVerse)"
        let passages = try await fetchPassage(query: query, includeVerseNumbers: true)
        guard let fullText = passages.first, !fullText.isEmpty else {
            throw ESVServiceError.noPassageFound
        }
        return parseNumberedVerses(fullText, book: book, chapter: chapter)
    }

    /// Search ESV text for a query string.
    public func search(query: String, limit: Int = 50) async throws -> [Verse] {
        guard let apiKey = APIConfig.esvAPIKey else {
            throw ESVServiceError.noAPIKey
        }

        var components = URLComponents(string: APIConfig.esvSearchURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page-size", value: "\(min(limit, 100))")
        ]

        guard let url = components?.url else {
            throw ESVServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ESVServiceError.invalidResponse(0)
        }
        guard httpResponse.statusCode == 200 else {
            throw ESVServiceError.invalidResponse(httpResponse.statusCode)
        }

        return try parseSearchResponse(data)
    }

    // MARK: - Private Helpers

    /// Fetch passage text from the ESV API.
    private func fetchPassage(query: String, includeVerseNumbers: Bool = false) async throws -> [String] {
        guard let apiKey = APIConfig.esvAPIKey else {
            throw ESVServiceError.noAPIKey
        }

        var components = URLComponents(string: APIConfig.esvBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "include-passage-references", value: "false"),
            URLQueryItem(name: "include-footnotes", value: "false"),
            URLQueryItem(name: "include-headings", value: "false"),
            URLQueryItem(name: "include-short-copyright", value: "false"),
            URLQueryItem(name: "include-verse-numbers", value: includeVerseNumbers ? "true" : "false"),
            URLQueryItem(name: "include-first-verse-numbers", value: "true"),
            URLQueryItem(name: "indent-paragraphs", value: "0"),
            URLQueryItem(name: "indent-poetry", value: "false"),
            URLQueryItem(name: "indent-psalm-doxology", value: "0")
        ]

        guard let url = components?.url else {
            throw ESVServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ESVServiceError.invalidResponse(0)
        }
        guard httpResponse.statusCode == 200 else {
            throw ESVServiceError.invalidResponse(httpResponse.statusCode)
        }

        return try parsePassageResponse(data)
    }

    /// Perform a URL request with error mapping.
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw ESVServiceError.networkError(error)
        }
    }

    /// Parse the ESV API passage response JSON.
    /// Response format: { "passages": ["verse text..."], "canonical": "John 3:16", ... }
    private func parsePassageResponse(_ data: Data) throws -> [String] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let passages = json["passages"] as? [String]
            else {
                throw ESVServiceError.noPassageFound
            }
            return passages
        } catch let error as ESVServiceError {
            throw error
        } catch {
            throw ESVServiceError.decodingError(error)
        }
    }

    /// Parse the ESV API search response JSON.
    /// Response format: { "results": [ { "reference": "...", "content": "..." }, ... ] }
    private func parseSearchResponse(_ data: Data) throws -> [Verse] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]]
            else {
                return []
            }

            return results.compactMap { result -> Verse? in
                guard let reference = result["reference"] as? String,
                      let content = result["content"] as? String
                else { return nil }

                let parsed = parseReference(reference)
                let cleaned = cleanVerseText(content)
                guard !cleaned.isEmpty else { return nil }

                return Verse(
                    id: syntheticID(book: parsed.book, chapter: parsed.chapter, verse: parsed.verse),
                    bookName: parsed.book,
                    chapterNumber: parsed.chapter,
                    verseNumber: parsed.verse,
                    text: cleaned,
                    translation: "ESV"
                )
            }
        } catch {
            throw ESVServiceError.decodingError(error)
        }
    }

    /// Parse numbered verse text like "[1] In the beginning... [2] The earth was..."
    /// into individual Verse objects.
    private func parseNumberedVerses(_ text: String, book: String, chapter: Int) -> [Verse] {
        // ESV returns verse numbers in brackets: [1] text [2] text ...
        let pattern = #"\[(\d+)\]\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // Fallback: return as single verse
            let cleaned = cleanVerseText(text)
            guard !cleaned.isEmpty else { return [] }
            return [Verse(
                id: syntheticID(book: book, chapter: chapter, verse: 1),
                bookName: book,
                chapterNumber: chapter,
                verseNumber: 1,
                text: cleaned,
                translation: "ESV"
            )]
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var verses: [Verse] = []
        for (i, match) in matches.enumerated() {
            let verseNumRange = match.range(at: 1)
            guard verseNumRange.location != NSNotFound,
                  let verseNum = Int(nsText.substring(with: verseNumRange))
            else { continue }

            let textStart = match.range.location + match.range.length
            let textEnd: Int
            if i + 1 < matches.count {
                textEnd = matches[i + 1].range.location
            } else {
                textEnd = nsText.length
            }

            let verseText = nsText.substring(with: NSRange(location: textStart, length: textEnd - textStart))
            let cleaned = cleanVerseText(verseText)
            guard !cleaned.isEmpty else { continue }

            verses.append(Verse(
                id: syntheticID(book: book, chapter: chapter, verse: verseNum),
                bookName: book,
                chapterNumber: chapter,
                verseNumber: verseNum,
                text: cleaned,
                translation: "ESV"
            ))
        }

        return verses
    }

    /// Clean up verse text: trim whitespace, collapse multiple spaces, remove stray newlines.
    private func cleanVerseText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
    }

    /// Parse a reference string like "John 3:16" into components.
    private func parseReference(_ reference: String) -> (book: String, chapter: Int, verse: Int) {
        if let ref = VerseParser.parse(reference) {
            return (ref.bookName, ref.chapter, ref.verse)
        }
        // Fallback: return the raw reference as book name
        return (reference, 1, 1)
    }

    /// Generate a synthetic verse ID for API-sourced verses.
    /// Uses a hash-based approach to create stable IDs that won't collide with SQLite row IDs.
    private func syntheticID(book: String, chapter: Int, verse: Int) -> Int {
        // Offset by 1_000_000 to avoid collision with KJV SQLite IDs
        var hasher = Hasher()
        hasher.combine("ESV")
        hasher.combine(book)
        hasher.combine(chapter)
        hasher.combine(verse)
        return abs(hasher.finalize()) % 10_000_000 + 1_000_000
    }
}

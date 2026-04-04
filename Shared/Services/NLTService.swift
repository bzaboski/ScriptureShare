import Foundation

/// Errors specific to NLT API interactions.
public enum NLTServiceError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)
    case parsingError
    case noPassageFound

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "NLT API key not configured. Add your key in APIConfig.swift."
        case .invalidURL:
            return "Invalid NLT API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "NLT API returned status \(code)."
        case .parsingError:
            return "Failed to parse NLT response."
        case .noPassageFound:
            return "No passage found for the given reference."
        }
    }
}

/// Fetches Bible verses from the NLT API (https://api.nlt.to/).
/// The NLT API returns HTML, which this service strips to extract plain text.
/// All methods are async and require a valid API key in APIConfig.
public final class NLTService: Sendable {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Fetch a single verse by book, chapter, and verse number.
    public func fetchVerse(book: String, chapter: Int, verse: Int) async throws -> Verse {
        let ref = "\(book) \(chapter):\(verse)"
        let html = try await fetchPassageHTML(ref: ref)
        let verses = parseHTMLToVerses(html, book: book, chapter: chapter)

        guard let found = verses.first(where: { $0.verseNumber == verse }) ?? verses.first else {
            throw NLTServiceError.noPassageFound
        }
        return found
    }

    /// Fetch all verses in a chapter.
    public func fetchVerses(book: String, chapter: Int) async throws -> [Verse] {
        let ref = "\(book) \(chapter)"
        let html = try await fetchPassageHTML(ref: ref)
        let verses = parseHTMLToVerses(html, book: book, chapter: chapter)

        guard !verses.isEmpty else {
            throw NLTServiceError.noPassageFound
        }
        return verses
    }

    /// Fetch a range of verses within a chapter.
    public func fetchVerseRange(book: String, chapter: Int, from startVerse: Int, through endVerse: Int) async throws -> [Verse] {
        let ref = "\(book) \(chapter):\(startVerse)-\(endVerse)"
        let html = try await fetchPassageHTML(ref: ref)
        let verses = parseHTMLToVerses(html, book: book, chapter: chapter)

        guard !verses.isEmpty else {
            throw NLTServiceError.noPassageFound
        }
        return verses
    }

    /// Search NLT text for a query string.
    /// Note: The NLT API does not have a dedicated search endpoint.
    /// This performs a reference-based lookup if the query looks like a reference,
    /// otherwise returns an empty result with an appropriate message.
    public func search(query: String, limit: Int = 50) async throws -> [Verse] {
        // Try to parse as a verse reference first
        if let ref = VerseParser.parse(query) {
            if let endVerse = ref.endVerse {
                return try await fetchVerseRange(
                    book: ref.bookName,
                    chapter: ref.chapter,
                    from: ref.verse,
                    through: endVerse
                )
            } else {
                let verse = try await fetchVerse(
                    book: ref.bookName,
                    chapter: ref.chapter,
                    verse: ref.verse
                )
                return [verse]
            }
        }

        // NLT API does not support keyword search — return empty
        return []
    }

    // MARK: - Private Helpers

    /// Fetch raw HTML from the NLT API for a given reference string.
    private func fetchPassageHTML(ref: String) async throws -> String {
        guard let apiKey = APIConfig.nltAPIKey else {
            throw NLTServiceError.noAPIKey
        }

        var components = URLComponents(string: APIConfig.nltBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "ref", value: ref),
            URLQueryItem(name: "version", value: "NLT"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else {
            throw NLTServiceError.invalidURL
        }

        let request = URLRequest(url: url)
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NLTServiceError.invalidResponse(0)
        }
        guard httpResponse.statusCode == 200 else {
            throw NLTServiceError.invalidResponse(httpResponse.statusCode)
        }

        guard let html = String(data: data, encoding: .utf8), !html.isEmpty else {
            throw NLTServiceError.parsingError
        }

        return html
    }

    /// Perform a URL request with error mapping.
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw NLTServiceError.networkError(error)
        }
    }

    /// Parse NLT HTML response into individual Verse objects.
    /// The NLT API returns HTML with verse numbers in <span class="verse-num"> tags.
    private func parseHTMLToVerses(_ html: String, book: String, chapter: Int) -> [Verse] {
        // Strategy: find verse number spans and extract text between them.
        // Common patterns:
        //   <span class="verse-num">16 </span>For God so loved...
        //   <p class="..."><span class="verse-num">1 </span>In the beginning...

        // First, try to extract verse-number tagged content
        let versePattern = #"<span[^>]*class="[^"]*verse-num[^"]*"[^>]*>\s*(\d+)\s*</span>"#
        guard let verseRegex = try? NSRegularExpression(pattern: versePattern, options: .dotMatchesLineSeparators) else {
            return fallbackParse(html, book: book, chapter: chapter)
        }

        let nsHTML = html as NSString
        let matches = verseRegex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        guard !matches.isEmpty else {
            return fallbackParse(html, book: book, chapter: chapter)
        }

        var verses: [Verse] = []

        for (i, match) in matches.enumerated() {
            let verseNumRange = match.range(at: 1)
            guard verseNumRange.location != NSNotFound,
                  let verseNum = Int(nsHTML.substring(with: verseNumRange))
            else { continue }

            // Text starts after this match, ends at next match or end of content
            let textStart = match.range.location + match.range.length
            let textEnd: Int
            if i + 1 < matches.count {
                textEnd = matches[i + 1].range.location
            } else {
                textEnd = nsHTML.length
            }

            guard textEnd > textStart else { continue }
            let rawText = nsHTML.substring(with: NSRange(location: textStart, length: textEnd - textStart))
            let cleaned = stripHTML(rawText)
            guard !cleaned.isEmpty else { continue }

            verses.append(Verse(
                id: syntheticID(book: book, chapter: chapter, verse: verseNum),
                bookName: book,
                chapterNumber: chapter,
                verseNumber: verseNum,
                text: cleaned,
                translation: "NLT"
            ))
        }

        return verses
    }

    /// Fallback parser: strip all HTML tags and return as a single verse.
    private func fallbackParse(_ html: String, book: String, chapter: Int) -> [Verse] {
        let text = stripHTML(html)
        guard !text.isEmpty else { return [] }
        return [Verse(
            id: syntheticID(book: book, chapter: chapter, verse: 1),
            bookName: book,
            chapterNumber: chapter,
            verseNumber: 1,
            text: text,
            translation: "NLT"
        )]
    }

    /// Strip HTML tags from a string and clean up whitespace.
    private func stripHTML(_ html: String) -> String {
        // Remove HTML tags
        var text = html.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#160;", " "),
            ("&mdash;", "\u{2014}"),
            ("&ndash;", "\u{2013}"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Clean whitespace
        text = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }

    /// Generate a synthetic verse ID for API-sourced verses.
    private func syntheticID(book: String, chapter: Int, verse: Int) -> Int {
        var hasher = Hasher()
        hasher.combine("NLT")
        hasher.combine(book)
        hasher.combine(chapter)
        hasher.combine(verse)
        return abs(hasher.finalize()) % 10_000_000 + 2_000_000
    }
}

import Foundation

public struct VerseReference: Equatable, Sendable {
    public let bookName: String
    public let chapter: Int
    public let verse: Int
    /// End verse for ranges (e.g. John 3:16-17). nil for single verses.
    public var endVerse: Int?
    public var translation: String

    public init(bookName: String, chapter: Int, verse: Int, endVerse: Int? = nil, translation: String = "KJV") {
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.endVerse = endVerse
        self.translation = translation
    }

    public var displayString: String {
        if let end = endVerse {
            return "\(bookName) \(chapter):\(verse)-\(end)"
        }
        return "\(bookName) \(chapter):\(verse)"
    }

    public var isRange: Bool { endVerse != nil }
}

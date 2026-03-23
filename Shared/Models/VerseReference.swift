import Foundation

public struct VerseReference: Equatable, Sendable {
    public let bookName: String
    public let chapter: Int
    public let verse: Int
    public var translation: String

    public init(bookName: String, chapter: Int, verse: Int, translation: String = "KJV") {
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.translation = translation
    }

    public var displayString: String {
        "\(bookName) \(chapter):\(verse)"
    }
}

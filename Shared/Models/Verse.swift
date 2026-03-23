import Foundation

public struct Verse: Identifiable, Equatable, Sendable {
    public let id: Int
    public let bookName: String
    public let chapterNumber: Int
    public let verseNumber: Int
    /// Optional end verse for ranges (e.g. 4-7).
    public let endVerseNumber: Int?
    public let text: String
    public let translation: String

    public init(
        id: Int,
        bookName: String,
        chapterNumber: Int,
        verseNumber: Int,
        endVerseNumber: Int? = nil,
        text: String,
        translation: String = "KJV"
    ) {
        self.id = id
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.endVerseNumber = endVerseNumber
        self.text = text
        self.translation = translation
    }

    public var reference: String {
        if let end = endVerseNumber {
            return "\(bookName) \(chapterNumber):\(verseNumber)-\(end)"
        }
        return "\(bookName) \(chapterNumber):\(verseNumber)"
    }

    public var formattedForSharing: String {
        "\"\(text)\"\n— \(reference) (\(translation))"
    }
}

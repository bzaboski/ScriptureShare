import Foundation

public struct Verse: Identifiable, Equatable, Sendable {
    public let id: Int
    public let bookName: String
    public let chapterNumber: Int
    public let verseNumber: Int
    public let text: String
    public let translation: String

    public init(
        id: Int,
        bookName: String,
        chapterNumber: Int,
        verseNumber: Int,
        text: String,
        translation: String = "KJV"
    ) {
        self.id = id
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.text = text
        self.translation = translation
    }

    public var reference: String {
        "\(bookName) \(chapterNumber):\(verseNumber)"
    }

    public var formattedForSharing: String {
        "\"\(text)\"\n— \(reference) (\(translation))"
    }
}

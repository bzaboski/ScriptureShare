import XCTest
@testable import ScriptureShare

final class SS02VerseParserTests: XCTestCase {

    var db: BibleDatabase!

    override func setUpWithError() throws {
        let bundle = Bundle(for: SS02VerseParserTests.self)
        db = BibleDatabase(bundle: bundle)
    }

    override func tearDownWithError() throws {
        db = nil
    }

    // MARK: - Parser Tests

    func testParseJohn3v16() throws {
        let ref = try XCTUnwrap(VerseParser.parse("John 3:16"))
        XCTAssertEqual(ref.bookName, "John")
        XCTAssertEqual(ref.chapter, 3)
        XCTAssertEqual(ref.verse, 16)
        XCTAssertNil(ref.endVerse)
    }

    func testParse1Corinthians13v4to7() throws {
        let ref = try XCTUnwrap(VerseParser.parse("1 Corinthians 13:4-7"))
        XCTAssertEqual(ref.bookName, "1 Corinthians")
        XCTAssertEqual(ref.chapter, 13)
        XCTAssertEqual(ref.verse, 4)
        XCTAssertEqual(ref.endVerse, 7)
    }

    func testParseGen1v1() throws {
        let ref = try XCTUnwrap(VerseParser.parse("Gen 1:1"))
        XCTAssertEqual(ref.bookName, "Genesis")
        XCTAssertEqual(ref.chapter, 1)
        XCTAssertEqual(ref.verse, 1)
        XCTAssertNil(ref.endVerse)
    }

    func testParsePsalm23v1to6() throws {
        let ref = try XCTUnwrap(VerseParser.parse("Psalm 23:1-6"))
        // "Psalm" abbreviation should resolve to "Psalms"
        XCTAssertEqual(ref.bookName, "Psalms")
        XCTAssertEqual(ref.chapter, 23)
        XCTAssertEqual(ref.verse, 1)
        XCTAssertEqual(ref.endVerse, 6)
    }

    func testInvalidReferenceReturnsNil() {
        XCTAssertNil(VerseParser.parse("NotABook 1:1"))
        XCTAssertNil(VerseParser.parse("John"))
        XCTAssertNil(VerseParser.parse(""))
        XCTAssertNil(VerseParser.parse("John 3"))
        XCTAssertNil(VerseParser.parse("John 3:16-10")) // end < start
    }

    func testAbbreviationMap66Books() {
        // Spot-check a variety of abbreviations
        XCTAssertEqual(VerseParser.resolve("gen"), "Genesis")
        XCTAssertEqual(VerseParser.resolve("GEN"), "Genesis")
        XCTAssertEqual(VerseParser.resolve("Rev"), "Revelation")
        XCTAssertEqual(VerseParser.resolve("1cor"), "1 Corinthians")
        XCTAssertEqual(VerseParser.resolve("ps"), "Psalms")
        XCTAssertEqual(VerseParser.resolve("mt"), "Matthew")
        XCTAssertEqual(VerseParser.resolve("rom"), "Romans")
        XCTAssertNil(VerseParser.resolve("xyz"))
    }

    // MARK: - Database Lookup Tests

    func testLookupJohn3v16() throws {
        let verse = try XCTUnwrap(db.verse(bookName: "John", chapter: 3, verse: 16))
        XCTAssertTrue(verse.text.contains("God so loved the world"))
    }

    func testLookupGen1v1() throws {
        let verse = try XCTUnwrap(db.verse(bookName: "Genesis", chapter: 1, verse: 1))
        XCTAssertTrue(verse.text.lowercased().contains("beginning"))
    }

    func testVerseRangeLookup1Cor13v4to7() throws {
        let verses = db.verses(bookName: "1 Corinthians", chapter: 13, from: 4, through: 7)
        XCTAssertEqual(verses.count, 4)
        XCTAssertEqual(verses.first?.verseNumber, 4)
        XCTAssertEqual(verses.last?.verseNumber, 7)
    }

    func testVerseRangeLookupPsalm23v1to6() throws {
        let verses = db.verses(bookName: "Psalms", chapter: 23, from: 1, through: 6)
        XCTAssertEqual(verses.count, 6)
        XCTAssertEqual(verses.first?.verseNumber, 1)
        XCTAssertEqual(verses.last?.verseNumber, 6)
    }

    func testInvalidReferenceDoesNotCrash() {
        // Should return nil gracefully, not crash
        let verse = db.verse(bookName: "NotABook", chapter: 1, verse: 1)
        XCTAssertNil(verse)
    }

    // MARK: - Superscript Formatting Tests

    func testSuperscriptSingleDigit() {
        XCTAssertEqual(VerseParser.superscript(1), "¹")
        XCTAssertEqual(VerseParser.superscript(9), "⁹")
    }

    func testSuperscriptMultiDigit() {
        XCTAssertEqual(VerseParser.superscript(16), "¹⁶")
        XCTAssertEqual(VerseParser.superscript(23), "²³")
    }

    func testFormatRangeInlineVerseNumbers() {
        // Build mock verses
        struct MockVerse: VerseProtocol {
            let verseNumber: Int
            let text: String
        }
        let verses: [any VerseProtocol] = [
            MockVerse(verseNumber: 16, text: "For God so loved the world"),
            MockVerse(verseNumber: 17, text: "For God sent not his Son"),
        ]
        let formatted = VerseParser.formatRange(verses)
        XCTAssertTrue(formatted.hasPrefix("¹⁶"))
        XCTAssertTrue(formatted.contains("¹⁷"))
        XCTAssertTrue(formatted.contains("For God so loved the world"))
        XCTAssertTrue(formatted.contains("For God sent not his Son"))
    }

    // MARK: - End-to-end range formatting from DB

    func testJohn3v16to17FormattedRange() throws {
        let verses = db.verses(bookName: "John", chapter: 3, from: 16, through: 17)
        XCTAssertEqual(verses.count, 2)
        let formatted = VerseParser.formatRange(verses)
        XCTAssertTrue(formatted.hasPrefix("¹⁶"), "Should start with superscript 16, got: \(formatted)")
        XCTAssertTrue(formatted.contains("¹⁷"), "Should contain superscript 17")
    }
}

import XCTest
@testable import ScriptureShare

final class BibleDatabaseTests: XCTestCase {

    var db: BibleDatabase!

    override func setUpWithError() throws {
        let bundle = Bundle(for: BibleDatabaseTests.self)
        db = BibleDatabase(bundle: bundle)
    }

    override func tearDownWithError() throws {
        db = nil
    }

    // MARK: - SS-01 Acceptance: John 3:16

    func testJohn3v16ReturnsExpectedKJVText() throws {
        let verse = db.verse(bookName: "John", chapter: 3, verse: 16)

        XCTAssertNotNil(verse, "John 3:16 should exist in the database")

        let text = try XCTUnwrap(verse?.text)
        XCTAssertTrue(
            text.contains("God so loved the world"),
            "Expected KJV text of John 3:16, got: \(text)"
        )
        XCTAssertEqual(verse?.bookName, "John")
        XCTAssertEqual(verse?.chapterNumber, 3)
        XCTAssertEqual(verse?.verseNumber, 16)
    }

    // MARK: - FTS5 Search

    func testFTS5SearchReturnsResults() throws {
        let results = db.search(query: "grace", limit: 10)
        XCTAssertFalse(results.isEmpty, "FTS5 search for 'grace' should return results")
    }

    func testFTS5SearchForJesusWept() throws {
        let results = db.search(query: "Jesus wept", limit: 5)
        XCTAssertFalse(results.isEmpty, "FTS5 search for 'Jesus wept' should return results")
    }

    // MARK: - Book List

    func testAllBooksReturns66Books() {
        let books = db.allBooks()
        XCTAssertEqual(books.count, 66, "KJV has 66 books")
    }

    func testGenesisIsFirstBook() {
        let books = db.allBooks()
        XCTAssertEqual(books.first?.name, "Genesis")
    }

    func testRevelationIsLastBook() {
        let books = db.allBooks()
        XCTAssertEqual(books.last?.name, "Revelation")
    }

    // MARK: - Chapter Queries

    func testJohnHas21Chapters() {
        let count = db.chapterCount(bookName: "John")
        XCTAssertEqual(count, 21)
    }

    func testJohn3HasVerses() {
        let verses = db.verses(bookName: "John", chapter: 3)
        XCTAssertFalse(verses.isEmpty)
        XCTAssertEqual(verses.first?.verseNumber, 1)
    }
}

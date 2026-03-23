import XCTest
@testable import ScriptureShare

final class SS08SearchTests: XCTestCase {

    var db: BibleDatabase!

    override func setUpWithError() throws {
        let bundle = Bundle(for: SS08SearchTests.self)
        db = BibleDatabase(bundle: bundle)
    }

    override func tearDownWithError() throws {
        db = nil
    }

    // MARK: - FTS5 Search

    func testKeywordSearchReturnsResults() {
        // KJV uses "charity suffereth long" — use a real KJV phrase
        let results = db.search(query: "charity suffereth long", limit: 50)
        XCTAssertFalse(results.isEmpty, "FTS5 search should return results for KJV phrase 'charity suffereth long'")
    }

    func testKeywordSearchCappedAt50() {
        let results = db.search(query: "the", limit: 50)
        XCTAssertLessThanOrEqual(results.count, 50, "Results should be capped at 50")
    }

    func testKeywordSearchNoResultsForGibberish() {
        let results = db.search(query: "xyzzyplugh", limit: 50)
        XCTAssertTrue(results.isEmpty, "Gibberish search should return no results")
    }

    func testFTS5SearchPerformance() {
        // Must complete in under 200ms for common queries
        let start = Date()
        _ = db.search(query: "grace", limit: 50)
        let elapsed = Date().timeIntervalSince(start) * 1000
        XCTAssertLessThan(elapsed, 200, "FTS5 search should complete in under 200ms, took \(elapsed)ms")
    }

    func testFTS5SearchPerformanceLove() {
        let start = Date()
        _ = db.search(query: "love", limit: 50)
        let elapsed = Date().timeIntervalSince(start) * 1000
        XCTAssertLessThan(elapsed, 200, "FTS5 search for 'love' should complete in under 200ms, took \(elapsed)ms")
    }

    // MARK: - Smart Detection

    func testReferenceQueryResolvesViaParser() {
        // "John 3:16" should resolve via parser, not FTS5
        guard let ref = VerseParser.parse("John 3:16") else {
            XCTFail("Parser should recognize 'John 3:16'")
            return
        }
        let verse = db.verse(bookName: ref.bookName, chapter: ref.chapter, verse: ref.verse)
        XCTAssertNotNil(verse)
        XCTAssertTrue(verse!.text.contains("God so loved"))
    }

    func testKeywordQueryUseFTS5() {
        // KJV keyword phrase should not parse as a reference
        let query = "charity suffereth"
        XCTAssertNil(VerseParser.parse(query), "Keyword query should not parse as reference")
        let results = db.search(query: query, limit: 10)
        XCTAssertFalse(results.isEmpty, "FTS5 search should find 'charity suffereth'")
    }

    // MARK: - Result Content

    func testResultsHaveReferenceAndText() {
        let results = db.search(query: "faith", limit: 5)
        XCTAssertFalse(results.isEmpty)
        for verse in results {
            XCTAssertFalse(verse.reference.isEmpty, "Verse should have a reference string")
            XCTAssertFalse(verse.text.isEmpty, "Verse should have text")
        }
    }
}

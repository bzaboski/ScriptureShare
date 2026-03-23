import XCTest
@testable import ScriptureShare
import SwiftData

final class SS07RecentsTests: XCTestCase {

    var settings: UserSettings!

    override func setUp() {
        settings = UserSettings()
    }

    override func tearDown() {
        settings = nil
    }

    func testAddRecentAppendsToFront() {
        RecentsService.addRecent(verseID: 100, to: settings)
        RecentsService.addRecent(verseID: 200, to: settings)
        XCTAssertEqual(settings.recentVerseIDs.first, 200, "Most recent should be first")
        XCTAssertEqual(settings.recentVerseIDs[1], 100)
    }

    func testDuplicateMoveToTop() {
        RecentsService.addRecent(verseID: 100, to: settings)
        RecentsService.addRecent(verseID: 200, to: settings)
        RecentsService.addRecent(verseID: 100, to: settings)
        XCTAssertEqual(settings.recentVerseIDs.first, 100, "Duplicate should move to top")
        XCTAssertEqual(settings.recentVerseIDs.count, 2, "No duplicates should remain")
    }

    func testMaxRecentsCapAt20() {
        for i in 1...25 {
            RecentsService.addRecent(verseID: i, to: settings)
        }
        XCTAssertEqual(settings.recentVerseIDs.count, 20, "Should cap at 20 recents")
    }

    func testClearRecents() {
        RecentsService.addRecent(verseID: 1, to: settings)
        RecentsService.addRecent(verseID: 2, to: settings)
        RecentsService.clearRecents(in: settings)
        XCTAssertTrue(settings.recentVerseIDs.isEmpty)
    }

    func testMostRecentIsFirst() {
        for i in 1...5 {
            RecentsService.addRecent(verseID: i, to: settings)
        }
        XCTAssertEqual(settings.recentVerseIDs.first, 5, "Last added should be first")
    }
}

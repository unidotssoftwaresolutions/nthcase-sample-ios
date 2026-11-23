import Foundation
import XCTest
@testable import MossgroveKit

/// Spec 1.2's rules (SPEC.md §5), as the screens use them: the quick sheet's More like this, and the Feed, a list that
/// brings 20 more rows each time its third row from the end shows, and never ends.
final class FeedLogicTests: XCTestCase {
    func testMoreLikeThisReadsAfterTheSheetsTitle() {
        XCTAssertEqual(Lobby.sheetMoreLines, 20)
        XCTAssertEqual(Lobby.moreLikeThis, "More like this")
        XCTAssertEqual(Lobby.sheetMoreLine(title: "Bedside Lamp", 1), "Like Bedside Lamp · 1 of 20")
        XCTAssertEqual(Lobby.sheetMoreLine(title: "Bedside Lamp", 20), "Like Bedside Lamp · 20 of 20")
        XCTAssertEqual(Lobby.sheetMoreLine(title: Lobby.bannerTitles[1], 7), "Like Warm, low desk lamps · 7 of 20")
        XCTAssertEqual(TestIds.lobbySheetMoreRow(20), "lobby_sheet_more_row_20")
        // a tap on a line is logged as a tap on a button is
        var log = TouchLog()
        log.add(.tap, Lobby.sheetMoreLine(title: "Bedside Lamp", 7), "quick sheet, Bedside Lamp")
        XCTAssertEqual(log.text, "Tapped: Like Bedside Lamp · 7 of 20 (quick sheet, Bedside Lamp)")
    }

    func testTheFeedsTexts() {
        XCTAssertEqual(Feed.row(1), "Feed row 1")
        XCTAssertEqual(Feed.row(61), "Feed row 61")
        XCTAssertEqual(Feed.loading, "Loading more rows…")
        XCTAssertEqual(Feed.title, "Feed")
        XCTAssertEqual(Feed.pageSize, 20)
        XCTAssertEqual(Feed.loadSeconds, 1)
        XCTAssertEqual(TestIds.feedRow(60), "feed_row_60")
    }

    /// A row shows when any part of it is inside the window: one whose top is the window's bottom edge does not.
    func testTheLastRowThatShows() {
        // 56-point rows in a 700-point window: rows 1-12 whole, row 13 in part
        XCTAssertEqual(Feed.lastShown(offset: 0, viewport: 700, rowHeight: 56, count: 20), 13)
        XCTAssertEqual(Feed.lastShown(offset: 28, viewport: 700, rowHeight: 56, count: 20), 13, "728 is row 14's top: not shown")
        XCTAssertEqual(Feed.lastShown(offset: 29, viewport: 700, rowHeight: 56, count: 20), 14)
        // row 18's top is 952: it shows once the window's foot passes it
        XCTAssertEqual(Feed.lastShown(offset: 252, viewport: 700, rowHeight: 56, count: 20), 17)
        XCTAssertEqual(Feed.lastShown(offset: 253, viewport: 700, rowHeight: 56, count: 20), 18)
        // past the last row (the spinner row, or a bounce), the last row is still the last that has come
        XCTAssertEqual(Feed.lastShown(offset: 500, viewport: 700, rowHeight: 56, count: 20), 20)
        // a pull down at the top
        XCTAssertEqual(Feed.lastShown(offset: -40, viewport: 700, rowHeight: 56, count: 20), 12)
        // nothing measured yet, or nothing of the rows in the window
        XCTAssertEqual(Feed.lastShown(offset: 0, viewport: 0, rowHeight: 56, count: 20), 0)
        XCTAssertEqual(Feed.lastShown(offset: 1120, viewport: 700, rowHeight: 56, count: 20), 0)
        // a larger font makes every row taller, the same for all
        XCTAssertEqual(Feed.lastShown(offset: 0, viewport: 700, rowHeight: 80, count: 20), 9)
    }

    /// 20 at first; the third row from the end starts a load; while it runs no other starts; it brings 20 more.
    func testALoadEachTimeTheThirdRowFromTheEndShows() {
        var feed = FeedState()
        XCTAssertEqual(feed.count, 20)
        XCTAssertFalse(feed.loading)
        XCTAssertEqual(feed.trigger, 18)
        XCTAssertFalse(feed.shown(upTo: 17))
        XCTAssertFalse(feed.loading)
        XCTAssertTrue(feed.shown(upTo: 18), "row 18 starts the first load")
        XCTAssertTrue(feed.loading)
        XCTAssertFalse(feed.shown(upTo: 20), "no second load while one runs")
        XCTAssertEqual(feed.count, 20, "the rows come only when the load is done")
        feed.loaded()
        XCTAssertEqual(feed.count, 40)
        XCTAssertFalse(feed.loading)
        XCTAssertEqual(feed.trigger, 38)
        XCTAssertFalse(feed.shown(upTo: 37))
        XCTAssertTrue(feed.shown(upTo: 38))
        feed.loaded()
        XCTAssertEqual(feed.count, 60)
        // it never ends
        for _ in 0..<50 {
            XCTAssertTrue(feed.shown(upTo: feed.count))
            feed.loaded()
        }
        XCTAssertEqual(feed.count, 1_060)
        // a load that is not running brings nothing
        feed.loaded()
        XCTAssertEqual(feed.count, 1_060)
    }
}

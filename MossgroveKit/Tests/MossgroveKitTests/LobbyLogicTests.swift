import Foundation
import XCTest
@testable import MossgroveKit

/// The Lobby's rules (SPEC.md §5, 1.1), as both builds use them: which item each tile shows, the log, the position
/// lines, the board's corner and when Saved appears.
final class LobbyLogicTests: XCTestCase {
    func testTilesShowTheSpecsItems() {
        XCTAssertEqual(Lobby.tileItem(row: 2, tile: 1).name, "Espresso Cup Pair")
        XCTAssertEqual(Lobby.tileItem(row: 3, tile: 15).number, "No. 035")
        XCTAssertEqual(Lobby.tileItem(row: 3, tile: 15).name, "Bedside Lamp")
        XCTAssertEqual(Lobby.tileItem(row: 4, tile: 20).id, ((3 * 10 + 19) % 40) + 1)
        XCTAssertEqual(Lobby.topItem(1).name, "Tea Mug")
        XCTAssertEqual(Lobby.topItem(2).name, "Pocket Notebook")
        XCTAssertEqual(Lobby.topItem(10).name, "Fruit Bowl")
        XCTAssertEqual(Lobby.gridItem(1).number, "No. 029")
        XCTAssertEqual(Lobby.gridItem(12).number, "No. 040")
        XCTAssertEqual(Lobby.item(row: Lobby.topRow, tile: 2), Lobby.topItem(2))
        XCTAssertEqual(Lobby.item(row: 3, tile: 15), Lobby.tileItem(row: 3, tile: 15))
    }

    func testPlacesAndLabels() {
        XCTAssertEqual(Lobby.tileWhere(row: 3, tile: 15), "row 3, tile 15")
        XCTAssertEqual(Lobby.tileWhere(row: Lobby.topRow, tile: 2), "top row, tile 2")
        XCTAssertEqual(Lobby.detailPlace(row: 3, tile: 15), "Row 3, tile 15")
        XCTAssertEqual(Lobby.detailPlace(row: Lobby.topRow, tile: 2), "Top 10, tile 2")
        XCTAssertEqual(Lobby.boardLabel(col: 1, row: 1), "A1")
        XCTAssertEqual(Lobby.boardLabel(col: 13, row: 18), "M18")
        XCTAssertEqual(Lobby.boardLabel(col: 26, row: 26), "Z26")
        XCTAssertEqual(Lobby.columnKey(13), "m")
        XCTAssertEqual(TestIds.lobbyBoardCell(Lobby.columnKey(13), 18), "lobby_board_cell_m18")
        XCTAssertEqual(TestIds.lobbyRowTile(3, 15), "lobby_row_3_tile_15")
        XCTAssertEqual(TestIds.lobbySavedDelayChoice(12), "lobby_saved_delay_12")
        XCTAssertEqual(Lobby.pagerPosition(4), "Banner 4 of 5")
        XCTAssertEqual(Lobby.rowPosition(row: 2, first: 1, last: 3), "Row 2: tiles 1–3 of 20")
        XCTAssertEqual(Lobby.rowPosition(row: 2, first: 4, last: 4), "Row 2: tile 4 of 20")
        XCTAssertEqual(Lobby.topRowPosition(first: 1, last: 3), "Top 10: tiles 1–3 of 10")
        XCTAssertEqual(Lobby.topRowPosition(first: 4, last: 4), "Top 10: tile 4 of 10")
        XCTAssertEqual(Lobby.boardPosition(col: 1, row: 1), "Board: top-left A1")
        XCTAssertEqual(Lobby.innerLine(7), "Line 7 of 30")
        XCTAssertEqual(Lobby.delays.map(Lobby.delayLabel), ["0 s", "3 s", "6 s", "12 s", "20 s"])
    }

    func testTheLogKeepsThreeAndCountsAll() {
        var log = TouchLog()
        XCTAssertEqual(log.text, "Nothing touched")
        XCTAssertEqual(log.countText, "Touches: 0")
        log.add(.tap, "Bedside Lamp", Lobby.tileWhere(row: 3, tile: 15))
        XCTAssertEqual(log.text, "Tapped: Bedside Lamp (row 3, tile 15)")
        log.add(.longPress, "Pocket Notebook", Lobby.tileWhere(row: Lobby.topRow, tile: 2))
        log.add(.doubleTap, "M18", "board")
        log.add(.tap, "Saved", "bar")
        XCTAssertEqual(log.lines, ["Tapped: Saved (bar)", "Double-tapped: M18 (board)", "Long-pressed: Pocket Notebook (top row, tile 2)"])
        XCTAssertEqual(log.countText, "Touches: 4")
        log.reset()
        XCTAssertEqual(log, TouchLog())
    }

    /// A phone 393 points wide shows tiles 1–3 of a row at rest; a quarter tile in, 2–4.
    func testFullyVisibleTiles() {
        XCTAssertTrue(Lobby.fullyVisible(offset: 0, viewport: 393, count: 20) == (1, 3))
        XCTAssertTrue(Lobby.fullyVisible(offset: 108, viewport: 393, count: 20) == (2, 4))
        XCTAssertTrue(Lobby.fullyVisible(offset: 1400, viewport: 120, count: 20) == (14, 14))
        XCTAssertTrue(Lobby.fullyVisible(offset: 1450, viewport: 100, count: 20) == (14, 14), "no whole tile: the one under the left edge")
        XCTAssertTrue(Lobby.fullyVisible(offset: 0, viewport: 393, count: 10) == (1, 3))
    }

    func testTheBoardsCornerAndThePagersBanner() {
        XCTAssertTrue(Lobby.boardTopLeft(x: 0, y: 0) == (1, 1))
        XCTAssertTrue(Lobby.boardTopLeft(x: 1, y: 0) == (2, 1), "a cell scrolled partly out is not counted")
        XCTAssertTrue(Lobby.boardTopLeft(x: 12 * 56, y: 17 * 56) == (13, 18))
        XCTAssertTrue(Lobby.boardTopLeft(x: 10_000, y: 10_000) == (26, 26))
        XCTAssertEqual(Lobby.banner(offset: 0, pageWidth: 361), 1)
        XCTAssertEqual(Lobby.banner(offset: 3 * 361, pageWidth: 361), 4)
        XCTAssertEqual(Lobby.banner(offset: 99_999, pageWidth: 361), 5)
    }

    /// Saved is absent until the delay has passed since the clock started; choosing a delay starts it again.
    func testSavedClock() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let clock = SavedClock(delay: 12, started: start)
        XCTAssertFalse(clock.shown(at: start.addingTimeInterval(11.8)))
        XCTAssertTrue(clock.shown(at: start.addingTimeInterval(12.0)))
        XCTAssertEqual(clock.remaining(at: start.addingTimeInterval(4)), 8)
        XCTAssertTrue(SavedClock(delay: 0, started: start).shown(at: start))
        // chosen 8 s after the Lobby opened: still 12 s from the choice
        let chosen = SavedClock(delay: 12, started: start.addingTimeInterval(8))
        XCTAssertFalse(chosen.shown(at: start.addingTimeInterval(19)))
        XCTAssertTrue(chosen.shown(at: start.addingTimeInterval(20)))
    }
}

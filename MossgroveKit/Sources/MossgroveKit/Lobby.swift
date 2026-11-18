import Foundation

/// The Lobby (SPEC.md §5, new in 1.1): what both of its builds share, the SwiftUI one and the UIKit one. The names,
/// the numbers and the texts are the spec's; the two screens only draw them.
public enum Lobby {
    public static let banners = 5
    public static let rows = 4
    public static let tiles = 20
    public static let gridCells = 12
    public static let innerLines = 30
    public static let board = 26
    /// The Top 10 row: fixed, outside the page, under the pager (or in its place when the pager is off).
    public static let topTiles = 10
    /// The row number that stands for the Top 10 row, which is not one of the page's rows 1–4.
    public static let topRow = 0

    /// "Saved appears after": the choices, in seconds. 0 is the default; SPEC.md §5 says why each one.
    public static let delays = [0, 3, 6, 12, 20]
    /// Auto-advance moves the pager every 4 s when it is on.
    public static let autoAdvanceSeconds = 4.0

    /// A tile is 100 points wide, the Top 10 row's drawing 64 high, a board cell 56 square, the board 280 square and
    /// the inner list 240 high.
    public static let tileWidth = 100.0
    public static let topBandHeight = 64.0
    public static let tileSpacing = 8.0
    public static let rowInset = 16.0
    public static let boardCell = 56.0
    public static let boardSide = 280.0
    public static let innerListHeight = 240.0

    public static let bannerTitles = [
        "New in the Kitchen aisle",
        "Warm, low desk lamps",
        "Ferns that like the shade",
        "Candles for long evenings",
        "Totes for market day",
    ]

    public static let chips = ["All", "Kitchen", "Desk", "Garden", "Home", "Under $20", "Under $40", "New", "Gifts", "Sets", "Lamps", "Candles"]

    public static let barItems = ["Home", "Live", "Saved", "Offers"]
    public static let sheetButtons = ["Open", "Preview", "Saved", "Rate"]

    /// Tile `tile` of row `row` (both from 1) shows item ((row − 1) × 10 + tile − 1) mod 40 + 1.
    public static func tileItem(row: Int, tile: Int) -> Item {
        Catalog.items[((row - 1) * 10 + tile - 1) % Catalog.items.count]
    }

    /// Tile `tile` (from 1) of the Top 10 row shows item tile + 30: No. 031 to No. 040.
    public static func topItem(_ tile: Int) -> Item { Catalog.items[tile + 29] }

    /// Grid cell `cell` (from 1) shows item cell + 28.
    public static func gridItem(_ cell: Int) -> Item { Catalog.items[cell + 27] }

    /// The item a tile shows, for a row from 1 to 4 or `topRow`.
    public static func item(row: Int, tile: Int) -> Item { row == topRow ? topItem(tile) : tileItem(row: row, tile: tile) }

    /// Where the log says a tile was touched: "row 3, tile 15" or "top row, tile 2".
    public static func tileWhere(row: Int, tile: Int) -> String { row == topRow ? "top row, tile \(tile)" : "row \(row), tile \(tile)" }

    /// The detail's place line: "Row 3, tile 15", or "Top 10, tile 2".
    public static func detailPlace(row: Int, tile: Int) -> String { row == topRow ? "Top 10, tile \(tile)" : "Row \(row), tile \(tile)" }

    /// "A1" … "Z26": column letter, then row number, both from 1.
    public static func boardLabel(col: Int, row: Int) -> String { "\(columnLetter(col))\(row)" }

    /// The column's letter in lower case, as the cell's id has it: `lobby_board_cell_m18`.
    public static func columnKey(_ col: Int) -> String { columnLetter(col).lowercased() }

    private static func columnLetter(_ col: Int) -> String { String(UnicodeScalar(UInt8(64 + col))) }

    public static func pagerPosition(_ banner: Int) -> String { "Banner \(banner) of \(banners)" }

    /// "Row 2: tiles 1–3 of 20"; the first alone when only one tile is fully visible.
    public static func rowPosition(row: Int, first: Int, last: Int) -> String {
        last <= first ? "Row \(row): tile \(first) of \(tiles)" : "Row \(row): tiles \(first)–\(last) of \(tiles)"
    }

    /// "Top 10: tiles 1–3 of 10"; the first alone when only one tile is fully visible.
    public static func topRowPosition(first: Int, last: Int) -> String {
        last <= first ? "Top 10: tile \(first) of \(topTiles)" : "Top 10: tiles \(first)–\(last) of \(topTiles)"
    }

    public static func boardPosition(col: Int, row: Int) -> String { "Board: top-left \(boardLabel(col: col, row: row))" }

    public static func innerLine(_ n: Int) -> String { "Line \(n) of \(innerLines)" }

    public static func delayLabel(_ seconds: Int) -> String { "\(seconds) s" }

    /// The first and last fully visible tiles (from 1) of a row of `count` tiles `width` wide with `spacing` between
    /// them and `inset` before the first, scrolled by `offset` in a window `viewport` wide. When no tile is whole, the
    /// one the window's left edge is on.
    public static func fullyVisible(offset: Double, viewport: Double, count: Int, width: Double = tileWidth,
                                    spacing: Double = tileSpacing, inset: Double = rowInset) -> (first: Int, last: Int) {
        var whole: [Int] = []
        for i in 0..<count {
            let start = inset + Double(i) * (width + spacing) - offset
            if start >= -0.5 && start + width <= viewport + 0.5 { whole.append(i + 1) }
        }
        if let first = whole.first, let last = whole.last { return (first, last) }
        let under = Int(((offset - inset) / (width + spacing)).rounded(.down)) + 1
        let tile = min(max(under, 1), count)
        return (tile, tile)
    }

    /// The board's top-left fully visible cell (column, row), from 1: a cell scrolled partly out is not counted.
    public static func boardTopLeft(x: Double, y: Double, cell: Double = boardCell) -> (col: Int, row: Int) {
        func index(_ offset: Double) -> Int { min(max(Int((offset / cell - 0.001).rounded(.up)) + 1, 1), board) }
        return (index(x), index(y))
    }

    /// The banner a pager scrolled by `offset` in pages `pageWidth` wide shows, from 1.
    public static func banner(offset: Double, pageWidth: Double) -> Int {
        guard pageWidth > 0 else { return 1 }
        return min(max(Int((offset / pageWidth).rounded()) + 1, 1), banners)
    }

    public static let nothingTouched = "Nothing touched"
    public static let touchLogLabel = "Touch log"
    public static let reset = "Reset"
    public static let savedAppearsAfter = "Saved appears after"
    public static let showThePager = "Show the pager"
    public static let autoAdvance = "Auto-advance"
    public static let testBanner = "A test banner"
    public static let grid = "Grid"
    public static let innerList = "Inner list"
    public static let footer = "End of the lobby"
    public static let footerNote = "A test bench: nothing here is for sale."
    public static let promoNote = "A test banner. Nothing here is for sale."
    public static let backToLobby = "Back to the lobby"
    public static let savedEmpty = "Saved: nothing yet"
    public static let title = "Lobby"
    public static let titleUIKit = "Lobby (UIKit)"
    public static let labLine = "A pager, rows, a grid, a list in the list, a board and a late bar item, with a touch log"
    public static let labLineUIKit = "The same Lobby, built with UIKit"
}

/// How a touch came: the words the touch log starts each line with.
public enum Touch: String, Sendable {
    case tap = "Tapped"
    case longPress = "Long-pressed"
    case doubleTap = "Double-tapped"
}

/// The Lobby's oracle: every tap, long press and double tap on a touchable element, newest first. It shows at most
/// three lines; the count keeps every touch since the last reset. Nothing that scrolls writes here.
public struct TouchLog: Equatable, Sendable {
    public private(set) var lines: [String] = []
    public private(set) var count = 0

    public init() {}

    public var text: String { lines.isEmpty ? Lobby.nothingTouched : lines.joined(separator: "\n") }
    public var countText: String { "Touches: \(count)" }

    public mutating func add(_ touch: Touch, _ what: String, _ place: String) {
        lines = Array((["\(touch.rawValue): \(what) (\(place))"] + lines).prefix(3))
        count += 1
    }

    public mutating func reset() {
        lines = []
        count = 0
    }
}

/// When the bar's Saved appears: `delay` seconds after the clock started, which is when the Lobby opened or a delay
/// was last chosen (SPEC.md §5, "Saved appears late").
public struct SavedClock: Equatable, Sendable {
    public let delay: Int
    public let started: Date

    public init(delay: Int, started: Date) {
        self.delay = delay
        self.started = started
    }

    public func shown(at now: Date) -> Bool { now.timeIntervalSince(started) >= Double(delay) }

    /// How long until Saved appears, 0 once it has.
    public func remaining(at now: Date) -> TimeInterval { max(0, Double(delay) - now.timeIntervalSince(started)) }
}

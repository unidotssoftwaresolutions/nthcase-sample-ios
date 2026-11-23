import Foundation

/// The Feed (SPEC.md §5, new in 1.2): a list that never ends. It opens with 20 rows. When the third row from the end of
/// what has come shows, a spinner row comes after the last row; 1 s later it goes and 20 more rows come. The screen only
/// draws this.
public enum Feed {
    /// Rows at the start, and rows each load brings.
    public static let pageSize = 20
    /// How long the spinner row shows before the next rows come.
    public static let loadSeconds = 1.0
    /// A row is 56 points high at the default text size (the screen scales it with the text).
    public static let rowHeight = 56.0

    public static let title = "Feed"
    public static let labLine = "A list that never ends, 20 rows at a time"
    public static let loading = "Loading more rows…"

    /// "Feed row 7".
    public static func row(_ n: Int) -> String { "Feed row \(n)" }

    /// The last row (from 1) any part of which is inside a window `viewport` high, scrolled by `offset`, over `count`
    /// rows `rowHeight` high from the top of the list; 0 when the window shows none. A row whose top is the window's
    /// bottom edge, or whose bottom is its top edge, does not show.
    public static func lastShown(offset: Double, viewport: Double, rowHeight: Double, count: Int) -> Int {
        guard viewport > 0, rowHeight > 0, count > 0, offset + viewport > 0 else { return 0 }
        let bottom = offset + viewport
        let last = Int((bottom / rowHeight).rounded(.up))
        guard Double(min(last, count)) * rowHeight > offset else { return 0 }
        return min(last, count)
    }
}

/// What the Feed holds: how many rows have come, and whether a load is running.
public struct FeedState: Equatable, Sendable {
    public private(set) var count = Feed.pageSize
    public private(set) var loading = false

    public init() {}

    /// The third row from the end of what has come, the one whose showing starts a load.
    public var trigger: Int { count - 2 }

    /// Rows up to `lastShown` show: starts a load, and says so, when the trigger row is among them and none runs.
    public mutating func shown(upTo lastShown: Int) -> Bool {
        guard !loading, lastShown >= trigger else { return false }
        loading = true
        return true
    }

    /// The load's second has passed: the spinner row goes and the next rows come.
    public mutating func loaded() {
        guard loading else { return }
        count += Feed.pageSize
        loading = false
    }
}

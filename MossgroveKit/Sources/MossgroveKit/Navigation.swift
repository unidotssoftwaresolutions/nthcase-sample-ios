import Foundation

/// The four tabs, in order (SPEC.md §4).
public enum AppTab: String, CaseIterable, Hashable, Sendable {
    case shop, cart, lab, settings

    public var title: String {
        switch self {
        case .shop: "Shop"
        case .cart: "Cart"
        case .lab: "Lab"
        case .settings: "Settings"
        }
    }
}

/// The screens below a tab.
public enum Route: Hashable, Sendable {
    /// The item page, with the id as written (a deep link may name an unknown one).
    case item(String)
    case form, gestures, careGuide, slow, orders, giftCards
}

/// The tabs and each tab's stack of screens.
///
/// **A tab always opens at its first screen** (SPEC.md §4): choosing a tab, the one already shown included, empties
/// its stack. No deeper screen is kept for a later visit, so a scenario that taps a tab lands on the same screen in
/// every framework.
public struct TabNavigation: Equatable, Sendable {
    public private(set) var selected: AppTab = .shop
    private var paths: [AppTab: [Route]] = [:]

    public init() {}

    public func path(_ tab: AppTab) -> [Route] { paths[tab] ?? [] }

    /// What the bar's buttons do, and what "View cart" or "Start shopping" do.
    public mutating func select(_ tab: AppTab) {
        paths[tab] = []
        selected = tab
    }

    /// A push or a pop inside a tab: the system's Back, the edge swipe, or a row that opens a screen.
    public mutating func setPath(_ path: [Route], for tab: AppTab) { paths[tab] = path }

    public mutating func push(_ route: Route) { paths[selected, default: []].append(route) }

    public mutating func pop() { _ = paths[selected]?.popLast() }

    /// A deep link's item opens on the Shop tab, so Back lands on the Shop.
    public mutating func openItem(_ rawId: String) {
        select(.shop)
        push(.item(rawId))
    }

    /// After sign-in or sign-out: the Shop, with nothing stacked anywhere.
    public mutating func reset() {
        paths = [:]
        selected = .shop
    }
}

/// The Cart tab's accessible label: "Cart", or "Cart, 2 items".
public func cartTabLabel(count: Int) -> String { count > 0 ? "Cart, \(itemCount(count))" : "Cart" }

public enum LoadStatus: Equatable, Sendable { case loading, failed, ready }

/// The local stand-in for a network load (there is no network). It runs each time its screen opens. It waits
/// [slowSeconds] when the screen is always slow or Settings › Slow loading is on, and fails its first attempt when
/// Settings › Fail the first load is on; Try again then succeeds. With both off it is ready at once.
public enum LoadPlan {
    /// How long a slow load takes: the same on every framework.
    public static let slowSeconds = 3.0
    /// How long a pull to refresh takes when loading is not slowed.
    public static let refreshSeconds = 0.8

    public static func first(slow: Bool, fail: Bool, attempt: Int) -> LoadStatus {
        slow ? .loading : afterWait(fail: fail, attempt: attempt)
    }

    public static func afterWait(fail: Bool, attempt: Int) -> LoadStatus { fail && attempt == 0 ? .failed : .ready }
}

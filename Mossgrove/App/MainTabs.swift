import MossgroveKit
import SwiftUI
import UIKit

/// The four tabs, each with its own NavigationStack (SPEC.md §12). Choosing a tab, the one already shown included,
/// returns it to its first screen (TabNavigation.select).
struct MainTabs: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView(selection: Binding(get: { model.navigation.selected }, set: { model.navigation.select($0) })) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                stack(for: tab)
                    .tabItem { Label { Text(tab.title) } icon: { Art.icon(Self.icon(tab)) } }
                    .tag(tab)
                    .badge(tab == .cart ? model.cart.itemCount : 0)
            }
        }
    }

    private func stack(for tab: AppTab) -> some View {
        NavigationStack(path: Binding(get: { model.navigation.path(tab) }, set: { model.navigation.setPath($0, for: tab) })) {
            root(of: tab)
                .navigationDestination(for: Route.self) { route in
                    // Screens below a tab hide the bar, as on Android, so the screen with no ids has none at all.
                    destination(route).toolbar(.hidden, for: .tabBar)
                }
        }
        .overlay(alignment: .bottom) { SnackbarHost() }
        .background(TabBarIds(cartLabel: cartTabLabel(count: model.cart.itemCount)))
    }

    @ViewBuilder
    private func root(of tab: AppTab) -> some View {
        switch tab {
        case .shop: ShopView()
        case .cart: CartView()
        case .lab: LabView()
        case .settings: SettingsScreen()
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .item(let id): ItemView(rawId: id)
        case .form: FormView()
        case .gestures: GesturesView()
        case .careGuide: CareGuideView()
        case .slow: SlowView()
        case .orders: OrdersView()
        case .giftCards: GiftCardsView()
        }
    }

    private static func icon(_ tab: AppTab) -> String {
        switch tab {
        case .shop: "shop"
        case .cart: "cart"
        case .lab: "lab"
        case .settings: "settings"
        }
    }
}

/// SwiftUI gives a tab item no accessibility identifier, so this reaches the UITabBarController under the TabView and
/// names its items: `nav_shop`, `nav_cart`, `nav_lab`, `nav_settings`. It also gives the Cart tab its spoken count
/// ("Cart, 2 items") and the badge its brass. It runs again whenever the count changes.
private struct TabBarIds: UIViewControllerRepresentable {
    let cartLabel: String

    func makeUIViewController(context: Context) -> Accessor { Accessor() }

    func updateUIViewController(_ accessor: Accessor, context: Context) {
        accessor.cartLabel = cartLabel
        accessor.apply()
    }

    final class Accessor: UIViewController {
        var cartLabel = "Cart"

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.isAccessibilityElement = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        func apply() {
            // after SwiftUI has finished updating the bar's items
            DispatchQueue.main.async { [weak self] in
                guard let self, let tabBar = self.findTabBarController()?.tabBar, let items = tabBar.items, items.count == AppTab.allCases.count else { return }
                let ids = [TestIds.navShop, TestIds.navCart, TestIds.navLab, TestIds.navSettings]
                for (item, id) in zip(items, ids) { item.accessibilityIdentifier = id }
                items[1].accessibilityLabel = self.cartLabel
                items[1].badgeColor = Palette.tertiary
                items[1].setBadgeTextAttributes([.foregroundColor: Palette.onTertiary], for: .normal)
            }
        }

        private func findTabBarController() -> UITabBarController? {
            if let found = tabBarController { return found }
            var queue: [UIViewController] = view.window?.rootViewController.map { [$0] } ?? []
            while !queue.isEmpty {
                let next = queue.removeFirst()
                if let found = next as? UITabBarController { return found }
                queue.append(contentsOf: next.children)
            }
            return nil
        }
    }
}

import MossgroveKit
import SwiftUI
import UIKit

/// The four tabs, each with its own NavigationStack, under the app's own tab bar. Choosing a tab, the one already
/// shown included, returns it to its first screen (TabNavigation.select).
///
/// The bar is the app's own, not SwiftUI's `TabView`, because a tab button must carry its id (`nav_shop` …) where
/// Appium reads it, on iOS 17 through 26. SwiftUI gives a tab item no identifier, and on iOS 26 the system bar's
/// buttons do not take one from their `UITabBarItem` either: the second CI run found no `nav_*` id in the tree,
/// screen after screen. Each tab here is a SwiftUI `Button` with its id, the shape every other button id of the app
/// has, and the same on every iOS (SPEC.md §12 names `TabView`; the README says why this app differs).
struct MainTabs: View {
    @Environment(AppModel.self) private var model
    @State private var keyboardUp = false

    var body: some View {
        let selected = model.navigation.selected
        VStack(spacing: 0) {
            // Only the tab in front exists, as with a tab bar: its screens appear afresh (a load starts again), and
            // no other tab's ids are in the tree.
            stack(for: selected).id(selected)
            // Screens below a tab hide the bar, as on Android, so the screen with no ids has none at all. The keyboard
            // covers the bar, as it covers a system tab bar.
            if model.navigation.path(selected).isEmpty && !keyboardUp {
                TabBar()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            // a hardware keyboard leaves only a short bar on screen, or none
            keyboardUp = frame.height > 100 && frame.minY < UIScreen.main.bounds.height
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardUp = false }
    }

    private func stack(for tab: AppTab) -> some View {
        NavigationStack(path: Binding(get: { model.navigation.path(tab) }, set: { model.navigation.setPath($0, for: tab) })) {
            root(of: tab)
                .navigationDestination(for: Route.self) { route in destination(route) }
        }
        .overlay(alignment: .bottom) { SnackbarHost() }
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
}

/// The bottom bar: four buttons in the spec's order, each one accessibility element with its id, its title as its
/// label ("Cart, 2 items" for the Cart), and Selected on the tab in front. The icon, the title and the brass badge
/// are drawing only.
private struct TabBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            tab(.shop, icon: "shop", id: TestIds.navShop)
            tab(.cart, icon: "cart", id: TestIds.navCart)
            tab(.lab, icon: "lab", id: TestIds.navLab)
            tab(.settings, icon: "settings", id: TestIds.navSettings)
        }
        .frame(minHeight: 49)
        .background {
            Color(Palette.surfaceContainer)
                .overlay(alignment: .top) { Color(Palette.outlineVariant).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tab(_ tab: AppTab, icon: String, id: String) -> some View {
        let selected = model.navigation.selected == tab
        let count = tab == .cart ? model.cart.itemCount : 0
        return Button { model.navigation.select(tab) } label: {
            VStack(spacing: 2) {
                Art.icon(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(alignment: .topTrailing) {
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(Color(Palette.onTertiary))
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Color(Palette.tertiary), in: Capsule())
                                .offset(x: 12, y: -6)
                        }
                    }
                Text(tab.title).font(.caption2.weight(.medium))
            }
            .foregroundStyle(selected ? Color(Palette.primary) : Color(Palette.onSurfaceVariant))
            .frame(maxWidth: .infinity, minHeight: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab == .cart ? cartTabLabel(count: count) : tab.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

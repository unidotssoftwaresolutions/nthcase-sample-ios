import MossgroveKit
import Observation
import UIKit

enum ThemeMode: CaseIterable { case system, light, dark }

/// A message in the bottom banner, iOS's stand-in for a snackbar, with an optional action.
struct Snack: Identifiable {
    let id = UUID()
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
}

/// A modal dialog: a title, a line of text, Cancel and a confirm button.
struct DialogRequest: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let confirmLabel: String
    let onConfirm: () -> Void
}

/// Everything the app remembers, in memory only. A cold start is always signed out with an empty cart, no orders and
/// Settings at their defaults, so every run begins from the same screen (SPEC.md §2).
@MainActor
@Observable
final class AppModel {
    /// Snackbars stay 10 s, so a test step after the action still finds them (SPEC.md §5).
    static let snackSeconds = 10.0

    private(set) var signedInEmail: String?
    private(set) var cart = Cart()
    private(set) var orders: [Order] = []
    var navigation = TabNavigation()

    /// Settings › Testing: every list load waits 3 s first.
    var slowLoading = false
    /// Settings › Testing: the first load of each visit fails; Try again then succeeds.
    var failFirstLoad = false
    /// Settings › Notifications: post "Order <n> placed" when notifications are allowed.
    var orderUpdates = false
    var themeMode: ThemeMode = .system {
        didSet { applyTheme() }
    }

    /// A deep link that arrived before sign-in; it opens right after.
    private(set) var pendingItemId: String?
    private(set) var snack: Snack?
    /// How far above the bottom of the screen the banner sits: the height of a panel the screen pins there (the Cart's
    /// total and Check out), so the banner never covers that panel's button. 0 elsewhere.
    var snackbarLift: CGFloat = 0
    private(set) var dialog: DialogRequest?
    private var snackTimer: Task<Void, Never>?

    let notifications = NotificationService()

    var signedIn: Bool { signedInEmail != nil }

    // MARK: Account

    func signIn(email: String) {
        signedInEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        navigation.reset()
        if let pending = pendingItemId {
            pendingItemId = nil
            navigation.openItem(pending)
        }
    }

    /// Back to the sign-in screen, with nothing stacked behind it.
    func signOut() {
        signedInEmail = nil
        cart.clear()
        orders.removeAll()
        navigation.reset()
        dialog = nil
        dismissSnack()
    }

    // MARK: Deep link

    func open(url: URL) {
        guard let id = DeepLinks.itemId(url) else { return }
        if signedIn {
            dialog = nil
            navigation.openItem(id)
        } else {
            pendingItemId = id
        }
    }

    // MARK: Cart and orders

    func add(_ itemId: Int, quantity: Int) { cart.add(itemId, quantity: quantity) }
    func setQuantity(_ itemId: Int, _ quantity: Int) { cart.setQuantity(itemId, quantity) }
    func remove(_ itemId: Int) { cart.remove(itemId) }

    @discardableResult
    func placeOrder() -> Order {
        let order = Order(number: orders.count + 1, lines: cart.lines)
        orders.insert(order, at: 0)
        cart.clear()
        if orderUpdates { notifications.post(title: Texts.orderPlaced(order.number), body: Texts.orderNotificationBody) }
        return order
    }

    /// Settings › Data: empties the cart and the order history, and keeps you signed in.
    func resetData() {
        cart.clear()
        orders.removeAll()
    }

    // MARK: Snackbar and dialog

    func showSnack(_ message: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        snackTimer?.cancel()
        let snack = Snack(message: message, actionLabel: actionLabel, action: action)
        self.snack = snack
        UIAccessibility.post(notification: .announcement, argument: message)
        snackTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.snackSeconds))
            guard !Task.isCancelled, self?.snack?.id == snack.id else { return }
            self?.snack = nil
        }
    }

    func performSnackAction() {
        let action = snack?.action
        dismissSnack()
        action?()
    }

    func dismissSnack() {
        snackTimer?.cancel()
        snack = nil
    }

    func showDialog(_ request: DialogRequest) { dialog = request }

    func closeDialog() { dialog = nil }

    // MARK: Theme

    /// Settings › Appearance applies to the whole app at once, the UIKit screen and its alert included.
    func applyTheme() {
        let style: UIUserInterfaceStyle = switch themeMode {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows { window.overrideUserInterfaceStyle = style }
        }
    }
}

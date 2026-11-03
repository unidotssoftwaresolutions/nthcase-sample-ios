import Foundation

/// The texts SPEC.md §6 fixes. The scenarios quote them, so every Mossgrove app shows the same words.
public enum Texts {
    // Sign in
    public static let appName = "Mossgrove"
    public static let tagline = "Home and desk goods"
    public static let testAccount = "Test account"
    public static let testAccountHelp = "This is a sample app. Sign in with:"
    public static let useTestAccount = "Use test account"
    public static let signIn = "Sign in"
    public static let signInMissing = "Enter your email and password"
    public static let signInWrong = "Wrong email or password"
    public static let showPassword = "Show password"
    public static let hidePassword = "Hide password"

    // Shop
    public static let searchPlaceholder = "Search by name or number"
    public static let clearSearch = "Clear search"
    public static let refreshed = "Catalogue is up to date"
    public static let shopLoading = "Opening the drawers…"
    public static let shopFailed = "The catalogue didn't load"
    public static let shopFailedHelp = "Something went wrong on our side. Your cart is safe."
    public static let tryAgain = "Try again"
    public static let noMatchHelp = "Try a shorter word, or an item number like 7."
    public static func noMatch(_ query: String) -> String { "No drawers match \"\(query)\"" }

    // Item
    public static let addedToCart = "Added to cart"
    public static let viewCart = "View cart"
    public static let notFound = "Not found"
    public static let backToShop = "Back to the shop"
    public static func addToCart(_ cents: Int) -> String { "Add to cart · \(formatPrice(cents))" }
    public static func noSuchItem(_ raw: String) -> String { "No drawer has the number \"\(raw)\"" }
    public static func itemsNumbered(_ count: Int) -> String { "Items are numbered 1 to \(count)." }
    public static func drawingOf(_ name: String) -> String { "Drawing of the \(name)" }

    // Cart
    public static let cartEmpty = "Your cart is empty"
    public static let cartEmptyHelp = "Open a drawer in the shop and add something."
    public static let browseShop = "Browse the shop"
    public static let total = "Total"
    public static let checkOut = "Check out"
    public static let placeThisOrder = "Place this order?"
    public static let cancel = "Cancel"
    public static let placeOrder = "Place order"
    public static let viewOrders = "View orders"
    public static func orderPlaced(_ number: Int) -> String { "Order \(number) placed" }
    public static func each(_ cents: Int) -> String { "\(formatPrice(cents)) each" }

    // Lab
    public static let labIntro = "Screens for testing. Each one exercises verbs that NthCase records and replays."

    // Form
    public static let formIntro = "Members hear about new drawers first. Every field is required except the newsletter."
    public static let join = "Join"
    public static let joined = "Welcome to the club"

    // Gestures
    public static let scrollHint = "Scroll to the bottom drawer. It is below the shelves."
    public static let openBottomDrawer = "Open the bottom drawer"
    public static let portrait = "Portrait"
    public static let landscape = "Landscape"

    // Care guide
    public static let pageLoading = "Loading the care guide…"
    public static let pageLoaded = "Care guide loaded"

    // Delivery slots
    public static let slotsLoading = "Finding delivery slots…"
    public static let slotsIntro = "Choose when we bring your order."
    public static let reload = "Reload"
    public static let slots = [
        "Monday · 8:00–10:00",
        "Monday · 18:00–20:00",
        "Wednesday · 12:00–14:00",
        "Friday · 8:00–10:00",
        "Saturday · 10:00–12:00",
    ]

    // Orders
    public static let ordersLoading = "Fetching your orders…"
    public static let ordersFailed = "Orders didn't load"
    public static let ordersFailedHelp = "Something went wrong on our side. Try again in a moment."
    public static let noOrders = "No orders yet"
    public static let noOrdersHelp = "Orders you place appear here."
    public static let startShopping = "Start shopping"
    public static func order(_ number: Int) -> String { "Order \(number)" }

    // Gift cards
    public static let checkBalance = "Check a balance"
    public static let cardCode = "Card code"
    public static let checkBalanceButton = "Check balance"
    public static let giftBalance = "Balance: $25.00"
    public static let giftUnknown = "We don't recognise that code"
    public static let buyCard = "Buy a card"
    public static let choose = "Choose"
    public static let giftChooseDesign = "Choose a design"

    // Settings
    public static let account = "Account"
    public static let notSignedIn = "Not signed in"
    public static let orderHistory = "Order history"
    public static let signOut = "Sign out"
    public static let appearance = "Appearance"
    public static let theme = "Theme"
    public static let themeSystem = "Follow the system"
    public static let themeLight = "Light"
    public static let themeDark = "Dark"
    public static let notifications = "Notifications"
    public static let orderUpdates = "Order updates"
    public static let notificationsNotAllowed = "Not allowed. Turn this on to be asked."
    public static let notificationsOff = "Off"
    public static let notificationsOn = "On: we'll tell you when an order is placed."
    public static let sendTestNotification = "Send a test notification"
    public static let testNotificationTitle = "Your order is packed"
    public static let testNotificationBody = "A test notification from Mossgrove."
    public static let orderNotificationBody = "We're packing it now."
    public static let notificationSent = "Notification sent"
    public static let testing = "Testing"
    public static let testingHelp = "These change how the shop's lists load. Nothing goes over the network."
    public static let slowLoading = "Slow loading (3 seconds)"
    public static let failFirstLoad = "Fail the first load"
    public static let data = "Data"
    public static let resetData = "Empty the cart and orders"
    public static let resetTitle = "Empty the cart and orders?"
    public static let resetBody = "You stay signed in. This can't be undone."
    public static let resetConfirm = "Empty"
    public static let resetDone = "Cart and orders emptied"
    public static let specVersion = "1.0"
    public static func version(_ app: String) -> String { "Mossgrove \(app) · spec \(specVersion) · a sample app for NthCase" }

    /// Settings › Notifications status line, from whether the system allows notifications and whether updates are on.
    public static func notificationStatus(allowed: Bool, on: Bool) -> String {
        !allowed ? notificationsNotAllowed : on ? notificationsOn : notificationsOff
    }
}

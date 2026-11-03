import Foundation

public struct CartLine: Hashable, Sendable {
    public let itemId: Int
    public var quantity: Int

    public var item: Item { Catalog.find(itemId)! }
    public var totalCents: Int { item.priceCents * quantity }
}

public struct Order: Hashable, Sendable {
    public let number: Int
    public let lines: [CartLine]

    public init(number: Int, lines: [CartLine]) {
        self.number = number
        self.lines = lines
    }

    public var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    public var totalCents: Int { lines.reduce(0) { $0 + $1.totalCents } }

    /// "2 items · Stoneware Mug, Brass Desk Lamp": the second line of an order's row.
    public var summary: String { "\(MossgroveKit.itemCount(itemCount)) · " + lines.map(\.item.name).joined(separator: ", ") }
}

/// The cart: one line per item, in the order items were first added. Quantities stay within 1–9.
public struct Cart: Hashable, Sendable {
    public static let minQuantity = 1
    public static let maxQuantity = 9

    public private(set) var lines: [CartLine] = []

    public init() {}

    public var isEmpty: Bool { lines.isEmpty }
    public var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    public var totalCents: Int { lines.reduce(0) { $0 + $1.totalCents } }

    public func quantity(of itemId: Int) -> Int { lines.first { $0.itemId == itemId }?.quantity ?? 0 }

    public mutating func add(_ itemId: Int, quantity: Int) {
        precondition(Catalog.find(itemId) != nil, "No item \(itemId)")
        if let index = lines.firstIndex(where: { $0.itemId == itemId }) {
            lines[index].quantity = Self.clamp(lines[index].quantity + quantity)
        } else {
            lines.append(CartLine(itemId: itemId, quantity: Self.clamp(quantity)))
        }
    }

    public mutating func setQuantity(_ itemId: Int, _ quantity: Int) {
        if let index = lines.firstIndex(where: { $0.itemId == itemId }) { lines[index].quantity = Self.clamp(quantity) }
    }

    public mutating func remove(_ itemId: Int) { lines.removeAll { $0.itemId == itemId } }

    public mutating func clear() { lines.removeAll() }

    static func clamp(_ quantity: Int) -> Int { min(max(quantity, minQuantity), maxQuantity) }
}

/// The checkout dialog's body: "2 items · $42.00. This is a sample shop: nothing is charged or shipped."
public func checkoutText(_ cart: Cart) -> String {
    "\(itemCount(cart.itemCount)) · \(formatPrice(cart.totalCents)). This is a sample shop: nothing is charged or shipped."
}

/// The test account, printed on the sign-in screen.
public enum Account {
    public static let email = "tester@mossgrove.test"
    public static let password = "Mossgrove123"

    /// Email case and surrounding spaces do not matter; the password's case does.
    public static func matches(email: String, password: String) -> Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == Account.email && password == Account.password
    }

    /// The sign-in screen's one check: nil when the credentials are right, otherwise the message to show.
    public static func signInError(email: String, password: String) -> String? {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty { return Texts.signInMissing }
        return matches(email: email, password: password) ? nil : Texts.signInWrong
    }
}

/// The one gift-card code that has a balance. Any other code is unknown.
public enum GiftCards {
    public static let code = "MOSS-0025"
    public static let amounts = [10, 25, 50]

    public static func check(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespaces) == Self.code ? Texts.giftBalance : Texts.giftUnknown
    }

    /// "A $25 card with the Stone design", or "Choose a design" before one is chosen.
    public static func choice(amount: Int, design: String?) -> String {
        design.map { "A $\(amount) card with the \($0) design" } ?? Texts.giftChooseDesign
    }
}

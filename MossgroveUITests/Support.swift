import Foundation
import XCTest

/// The spec's id list, `nthcase/test-ids.json`, bundled into this test target unchanged.
struct SpecIds: Decodable {
    struct Entry: Decodable {
        let id: String
        let screen: String
        let when: String
    }

    let ids: [Entry]

    static let shared: SpecIds = {
        let bundle = Bundle(for: BundleToken.self)
        let url = bundle.url(forResource: "test-ids", withExtension: "json")!
        return try! JSONDecoder().decode(SpecIds.self, from: Data(contentsOf: url))
    }()

    /// The native ids: everything but the `web_*` HTML ids, which only a WEBVIEW context can see.
    var native: [Entry] { ids.filter { !$0.id.hasPrefix("web_") } }

    /// Whether a concrete id ("shop_item_7") is an instance of a list entry ("shop_item_{id}").
    static func matches(_ concrete: String, _ entry: String) -> Bool {
        guard entry.contains("{") else { return concrete == entry }
        let prefix = entry.prefix { $0 != "{" }
        let tail = concrete.dropFirst(prefix.count)
        return concrete.hasPrefix(prefix) && !tail.isEmpty && tail.allSatisfy { $0.isLetter || $0.isNumber }
    }
}

private final class BundleToken {}

extension XCUIApplication {
    /// Any element whose accessibility identifier is `id`: what Appium's `accessibility id` locator finds.
    func id(_ id: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    /// Every identifier in the tree right now, read in one pass.
    func identifiers() -> [String] {
        guard let root = try? snapshot() else { return [] }
        var ids: [String] = []
        func walk(_ node: XCUIElementSnapshot) {
            if !node.identifier.isEmpty { ids.append(node.identifier) }
            node.children.forEach(walk)
        }
        walk(root)
        return ids
    }

    /// Any element showing `text`, in its label or its value.
    func text(_ text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }

    func signIn() {
        let email = id("signin_email")
        XCTAssertTrue(email.waitForExistence(timeout: 15), "the sign-in screen did not open")
        id("signin_use_test_account").tap()
        id("signin_submit").tap()
        XCTAssertTrue(id("shop_screen").waitForExistence(timeout: 10), "the shop did not open after sign-in")
    }

    /// A tab, by its id, or by its place in the bar if the id did not reach the tree (the walk reports that).
    func tab(_ index: Int, _ id: String) -> XCUIElement {
        let byId = self.id(id)
        return byId.exists ? byId : tabBars.buttons.element(boundBy: index)
    }

    func openTab(_ index: Int, _ id: String) { tab(index, id).tap() }

    func openLab(_ bench: String) {
        openTab(2, "nav_lab")
        let row = id(bench)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(bench) is not on the Lab")
        row.tap()
    }

    func back() { id("top_bar_back").tap() }

    /// Scrolls until the element is on screen and can be tapped.
    @discardableResult
    func scrollTo(_ element: XCUIElement, up: Bool = false, tries: Int = 15) -> XCUIElement {
        var left = tries
        while !(element.exists && element.isHittable) && left > 0 {
            if up { swipeDown() } else { swipeUp() }
            left -= 1
        }
        return element
    }
}

extension XCUIElement {
    /// The text an element shows: its value for a field, otherwise its label.
    var shown: String {
        if elementType == .textField || elementType == .secureTextField { return (value as? String) ?? "" }
        return label
    }

    /// What a text field holds, without its placeholder.
    var typed: String {
        let current = (value as? String) ?? ""
        return current == (placeholderValue ?? "") ? "" : current
    }

    /// Types at the end of what the field already holds.
    func type(_ text: String) {
        focusAtEnd()
        typeText(text)
    }

    /// Empties a text field, then types.
    func replace(with text: String) {
        let current = typed
        focusAtEnd()
        if !current.isEmpty { typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)) }
        typeText(text)
    }

    /// An element tap scrolls the field into view and focuses it. When it already holds text, a second tap past the
    /// text puts the cursor at its end (a coordinate tap alone would not scroll, and could land on the keyboard).
    private func focusAtEnd() {
        let holdsText = !typed.isEmpty
        tap()
        guard holdsText else { return }
        Thread.sleep(forTimeInterval: 0.6) // not a double tap, which would select a word
        coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
    }

    /// Turns a switch on or off, and checks that it moved.
    func set(_ on: Bool) {
        if isOn == on { return }
        tap()
        if isOn != on { coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap() }
        XCTAssertEqual(isOn, on, "\(identifier) did not turn \(on ? "on" : "off")")
    }

    var isOn: Bool { (value as? String) == "1" || (value as? Int) == 1 || (value as? Bool) == true }

    /// Waits until the element's label or value contains `text`.
    @discardableResult
    func waitFor(_ text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: self)], timeout: timeout) == .completed
    }

    func waitToVanish(timeout: TimeInterval = 5) -> Bool {
        XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: self)], timeout: timeout) == .completed
    }
}

/// The system's notification prompt, which Springboard draws. Allows it if it is there.
func allowNotificationsIfAsked() {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let allow = springboard.alerts.buttons["Allow"]
    if allow.waitForExistence(timeout: 8) { allow.tap() }
}

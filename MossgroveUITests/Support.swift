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

    /// A tab button, by its id, or by its title if the id did not reach the tree (the walk reports that, and
    /// testEveryTabIsTheButtonAPersonTaps fails on it). The bar is shown on the four tabs' first screens only, as on
    /// Android: from a screen below a tab, go Back first, as a person and NthCase do.
    func tab(_ id: String) -> XCUIElement {
        let byId = self.id(id)
        guard !byId.exists, let title = Self.tabTitles[id] else { return byId }
        return buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, "\(title),")).firstMatch
    }

    static let tabTitles = ["nav_shop": "Shop", "nav_cart": "Cart", "nav_lab": "Lab", "nav_settings": "Settings"]

    func openTab(_ id: String) { tab(id).tap() }

    func openLab(_ bench: String) {
        openTab("nav_lab")
        let row = id(bench)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(bench) is not on the Lab")
        row.tap()
    }

    func back() { id("top_bar_back").tap() }

    /// Hands a link to the running app the way the system does when a person opens one elsewhere (and as
    /// `xcrun simctl openurl` does for NthCase). `XCUIApplication.open(_:)` relaunched the app instead (second CI
    /// run), and a cold start is signed out. If SpringBoard asks whether to open Mossgrove, this answers Open.
    func openLinkWhileRunning(_ link: String, file: StaticString = #filePath, line: UInt = #line) {
        XCUIDevice.shared.system.open(URL(string: link)!)
        let open = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
        if open.waitForExistence(timeout: 5) { open.tap() }
        XCTAssertTrue(wait(for: .runningForeground, timeout: 15), "the app is not in front after \(link)", file: file, line: line)
    }

    /// A link from a cold start: the app is ended first, then launched with the link, so it starts signed out.
    func openLinkFromColdStart(_ link: String) {
        terminate()
        open(URL(string: link)!)
    }

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
    func type(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        guard focusAtEnd(file: file, line: line) else { return }
        typeText(text)
    }

    /// Empties a text field, then types.
    func replace(with text: String, file: StaticString = #filePath, line: UInt = #line) {
        let current = typed
        guard focusAtEnd(file: file, line: line) else { return }
        if !current.isEmpty { typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)) }
        typeText(text)
    }

    var hasFocus: Bool { (value(forKey: "hasKeyboardFocus") as? Bool) ?? false }

    /// The field, or something inside it, has the cursor.
    var holdsFocus: Bool { hasFocus || descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == true")).count > 0 }

    /// A field that already has the cursor is typed into as it is, as Appium's typing does (WebDriverAgent taps a
    /// field only when it lacks keyboard focus): the app keeps the cursor at the end of what it holds.
    ///
    /// Otherwise, one tap on the field, as a person and Appium make it: it scrolls the field into view and must focus
    /// it. When it already holds text, a second tap past the text puts the cursor at its end (a coordinate tap alone
    /// would not scroll, and could land on the keyboard).
    ///
    /// Then it waits up to 3 s for the focus, as Appium's typing waits for the keyboard, and never taps again: a field
    /// that one tap does not focus is the app's defect, and the failure says where the focus went instead.
    private func focusAtEnd(file: StaticString, line: UInt) -> Bool {
        if holdsFocus { return true }
        let holdsText = !typed.isEmpty
        tap()
        if holdsText {
            Thread.sleep(forTimeInterval: 0.6) // not a double tap, which would select a word
            coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        }
        let focused = NSPredicate { object, _ in (object as? XCUIElement)?.holdsFocus ?? false }
        if XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: focused, object: self)], timeout: 3) == .completed { return true }
        reportNoFocus(file: file, line: line)
        return false
    }

    /// What the next run needs to fix a field that a tap did not focus: where the tap went, who holds the focus,
    /// whether a keyboard is up, the screen and the whole tree.
    private func reportNoFocus(file: StaticString, line: UInt) {
        let app = XCUIApplication()
        let holder = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == true")).firstMatch
        let holderText = holder.exists ? "an element of type \(holder.elementType.rawValue), '\(holder.identifier)', '\(holder.label)'" : "nothing"
        let keyboard = app.keyboards.firstMatch.exists ? "a keyboard is up" : "no keyboard is up"
        XCTContext.runActivity(named: "No keyboard focus on \(identifier)") { activity in
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "after the tap on \(identifier)"
            shot.lifetime = .keepAlways
            activity.add(shot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "the tree after the tap on \(identifier)"
            tree.lifetime = .keepAlways
            activity.add(tree)
        }
        XCTFail("one tap on \(identifier) (\(label)) at (\(frame.midX), \(frame.midY)) did not give it keyboard focus within 3 s; "
                + "the focus is on \(holderText); \(keyboard); hittable: \(isHittable); frame: \(frame)", file: file, line: line)
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

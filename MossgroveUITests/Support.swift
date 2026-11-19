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
    /// AMENDED (1.1): each placeholder stands for letters and digits, wherever it is in the entry, so
    /// "lobby_row_3_tile_15" is an instance of "lobby_row_{n}_tile_{m}" and not of "lobby_row_{n}", and
    /// "lobby_board_cell_m18" of "lobby_board_cell_{col}{row}".
    static func matches(_ concrete: String, _ entry: String) -> Bool {
        guard entry.contains("{") else { return concrete == entry }
        let pattern = "^" + NSRegularExpression.escapedPattern(for: entry)
            .replacingOccurrences(of: #"\\\{\w+\\\}|\{\w+\}"#, with: "[a-z0-9]+", options: .regularExpression) + "$"
        return concrete.range(of: pattern, options: .regularExpression) != nil
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
        email.mustAppear(timeout: 15, "the sign-in screen: signin_email")
        id("signin_use_test_account").tapWhenThere()
        id("signin_submit").tapWhenThere()
        id("shop_screen").mustAppear(timeout: 10, "the shop after sign-in: shop_screen")
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

    func openTab(_ id: String) { tab(id).tapWhenThere() }

    func openLab(_ bench: String) {
        openTab("nav_lab")
        id(bench).tapWhenThere()
    }

    /// Back, as a person and NthCase go back: the button, then the screen below once it is there. The pop is an
    /// animation; until it ends the screen below is not in the tree yet, or a tap on it is lost (UIKit takes no touch
    /// during a navigation transition). The third CI run tapped `lab_webview` right after Back from Gestures: the walk
    /// found no such element, and the dark screenshots' tap opened nothing.
    ///
    /// Every screen with Back sits one level below a tab, so the screen below has no Back: Back has worked when
    /// `top_bar_back` is gone.
    func back(file: StaticString = #filePath, line: UInt = #line) {
        let button = id("top_bar_back")
        guard button.tapWhenThere(file: file, line: line) else { return }
        button.mustVanish(timeout: looksTimeout, "Back did not leave the screen: top_bar_back", file: file, line: line)
        // Leaving a filled password field is when iOS asks to save it (fourth CI run, after Join the club).
        answerSavePasswordCard(within: 1.5, file: file, line: line)
    }

    /// Hands a link to the running app the way the system does when a person opens one elsewhere (and as
    /// `xcrun simctl openurl` does for NthCase). `XCUIApplication.open(_:)` relaunched the app instead (second CI
    /// run), and a cold start is signed out. If SpringBoard asks whether to open Mossgrove, this answers Open.
    func openLinkWhileRunning(_ link: String, file: StaticString = #filePath, line: UInt = #line) {
        XCUIDevice.shared.system.open(URL(string: link)!)
        let open = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
        if open.appears(timeout: 5).met { open.tap() }
        Looks.until(timeout: 15) { ("state \(self.state.rawValue)", self.state == .runningForeground) }
            .check("the app is not in front after \(link) (4 is in front)", file: file, line: line)
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

extension XCUIApplication {
    /// The Lobby's page, scrolled by a drag in its left margin (8 points in, where no row, grid, inner list or board
    /// is), until `element` is on screen or the page stops moving. A swipe at the screen's centre could land on a tile
    /// row, the inner list or the board and move that instead.
    ///
    /// `gently`: each drag is slow and holds still before it lifts, so the page does not fling on and moves only the
    /// drag's own 60 % of its height. A flung drag can carry a small element past the page's view between two looks.
    /// If the element is in the tree but has gone past the page's view all the same, the next gentle drag goes back
    /// toward it.
    @discardableResult
    func scrollLobbyPage(until element: XCUIElement, up: Bool = false, gently: Bool = false, tries: Int = 25) -> XCUIElement {
        let page = id("lobby_page")
        guard page.appears(timeout: looksTimeout).met else { return element }
        var left = tries
        while !(element.exists && element.isHittable) && left > 0 {
            let frame = page.frame
            let origin = coordinate(withNormalizedOffset: .zero)
            let low = origin.withOffset(CGVector(dx: frame.minX + 8, dy: frame.minY + frame.height * 0.8))
            let high = origin.withOffset(CGVector(dx: frame.minX + 8, dy: frame.minY + frame.height * 0.2))
            var upward = up
            if gently && element.exists {
                let at = element.frame
                if !up && at.maxY <= frame.minY { upward = true }
                if up && at.minY >= frame.maxY { upward = false }
            }
            let (from, to) = upward ? (high, low) : (low, high)
            if gently {
                from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.2)
            } else {
                from.press(forDuration: 0.05, thenDragTo: to)
            }
            left -= 1
        }
        return element
    }

    /// A long press as NthCase makes one: the element is waited for, then pressed for a second.
    func longPressWhenThere(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        guard element.mustAppear(timeout: 8, "could not long-press \(element.description)", file: file, line: line) else { return }
        element.press(forDuration: 1.0)
    }
}

/// What a test could not do: a tap on an element that never came. In the id walk each one is kept for the walk's
/// one failure at its end, beside the ids each screen missed, and the walk goes on to its next step; anywhere else it
/// fails the test where it happened.
enum Misses {
    nonisolated(unsafe) private static var kept: [String]?

    /// Keeps every miss from here on, instead of failing at each.
    static func keep() { kept = [] }

    /// The misses kept since the last call, and keeps on.
    static func take() -> [String] {
        defer { if kept != nil { kept = [] } }
        return kept ?? []
    }

    static func stopKeeping() { kept = nil }

    static func report(_ text: String, file: StaticString, line: UInt) {
        if kept != nil { kept?.append(text) } else { XCTFail(text, file: file, line: line) }
    }
}

extension XCUIElement {
    /// A tap as NthCase makes one: it finds the element first, waiting up to `timeout` for it to be in the tree, then
    /// taps (XCUITest's tap scrolls a row below the fold into view, as before). XCUITest's own `tap()` waits for
    /// nothing: an element still on its way fails at once ("No matches found"), and in the id walk that ended the
    /// whole walk (third CI run). A miss says what was missing and which screen was there; the walk keeps it and goes
    /// on to its next step.
    ///
    /// An element that is there, on screen, and still not hittable is covered. It gets 3 s to come free (a screen
    /// still settling), then the miss names what covers it and the tap is not made: XCUITest's own tap on it fails
    /// "not hittable" and ends the test, and in the fourth CI run that ended the id walk at `lab_webview` with seven
    /// steps unchecked. What covered it was iOS's "Save Password?" card.
    @discardableResult
    func tapWhenThere(timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let app = XCUIApplication()
        // the card swallows every tap beneath it, even on an element XCUITest calls hittable
        app.answerSavePasswordCard(file: file, line: line)
        guard mustAppear(timeout: timeout, "could not tap \(description)", file: file, line: line) else { return false }
        // Below the fold, or under a bar, is XCUITest's to scroll into view. Only a cover the tree names stops the tap.
        if !isHittable && !waitForHittable(timeout: 3) {
            let cover = app.whatCovers(self)
            if cover != XCUIApplication.nothingNamed {
                Misses.report("could not tap \(description) at \(frame): not hittable after 3 s; covered by \(cover)",
                              file: file, line: line)
                return false
            }
        }
        tap()
        return true
    }

    func waitForHittable(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isHittable { return true }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return isHittable
    }

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

    /// The field, or something inside it, has the cursor. A text field is asked once: it has nothing inside it.
    var holdsFocus: Bool {
        if hasFocus { return true }
        if elementType == .textField || elementType == .secureTextField { return false }
        return descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == true")).count > 0
    }

    /// A field that already has the cursor is typed into as it is, as Appium's typing does (WebDriverAgent taps a
    /// field only when it lacks keyboard focus): the app keeps the cursor at the end of what it holds.
    ///
    /// Otherwise, one tap on the field, as a person and Appium make it: it scrolls the field into view and must focus
    /// it. When it already holds text, a second tap past the text puts the cursor at its end (a coordinate tap alone
    /// would not scroll, and could land on the keyboard).
    ///
    /// Then it waits up to 3 s for the focus and never taps again: a field that one tap does not focus is the app's
    /// defect, and the failure says where the focus went instead.
    ///
    /// The question is the focus, not the keyboard: typing needs the focus (XCUITest's typeText, and WebDriverAgent's
    /// typing for NthCase, type into the element that has it), and a keyboard need not be up for it, nor a software one
    /// at all. The third CI run failed a field that had the focus by the time the failure was written ("the focus is
    /// on … 'form_password'"): the wait asked through a predicate expectation, which XCTest polls about once a second,
    /// each look two queries of the whole tree. Now it looks every quarter second, one query each, and a miss says
    /// when the focus came after all, and when a keyboard did, so a slow field and a field that never takes the focus
    /// read differently.
    private func focusAtEnd(file: StaticString, line: UInt) -> Bool {
        if holdsFocus { return true }
        let holdsText = !typed.isEmpty
        tap()
        if holdsText {
            Thread.sleep(forTimeInterval: 0.6) // not a double tap, which would select a word
            coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        }
        let tapped = Date()
        if waitForFocus(until: tapped.addingTimeInterval(3)) { return true }
        // Missed. Watch 7 s more, only to say what happened; the check has already failed.
        var focusAfter: TimeInterval?
        var keyboardAfter: TimeInterval?
        let app = XCUIApplication()
        while Date().timeIntervalSince(tapped) < 10 && (focusAfter == nil || keyboardAfter == nil) {
            if focusAfter == nil && holdsFocus { focusAfter = Date().timeIntervalSince(tapped) }
            if keyboardAfter == nil && app.keyboards.firstMatch.exists { keyboardAfter = Date().timeIntervalSince(tapped) }
            Thread.sleep(forTimeInterval: 0.25)
        }
        func when(_ seconds: TimeInterval?) -> String { seconds.map { String(format: "after %.1f s", $0) } ?? "not within 10 s" }
        reportNoFocus(later: "the focus came \(when(focusAfter)), a keyboard \(when(keyboardAfter))", file: file, line: line)
        return false
    }

    /// Looks for the focus every quarter second, one query each, until the deadline; the last look is at the deadline.
    private func waitForFocus(until deadline: Date) -> Bool {
        while true {
            if holdsFocus { return true }
            if Date() >= deadline { return false }
            Thread.sleep(forTimeInterval: min(0.25, max(0, deadline.timeIntervalSinceNow)))
        }
    }

    /// What the next run needs to fix a field that a tap did not focus: where the tap went, who holds the focus,
    /// whether a keyboard is up, the screen and the whole tree.
    private func reportNoFocus(later: String, file: StaticString, line: UInt) {
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
        Misses.report("one tap on \(identifier) (\(label)) at (\(frame.midX), \(frame.midY)) did not give it keyboard focus within 3 s; "
                + "\(later); now the focus is on \(holderText); \(keyboard); hittable: \(isHittable); frame: \(frame)", file: file, line: line)
    }

    /// Turns a switch on or off with one tap on the element, as a person and NthCase do, and checks that it moved.
    ///
    /// One tap, then up to 2 s for the value. No second tap at a guessed point: in the fourth CI run the first tap
    /// landed on the switch's label (XCUITest's hit point for the element) and the second at 85 % of its width, both
    /// on the password's keyboard, which lay over the switch. A miss now says where the tap went and what lay there.
    func set(_ on: Bool, file: StaticString = #filePath, line: UInt = #line) {
        if isOn == on { return }
        let app = XCUIApplication()
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists && keyboard.frame.intersects(frame) {
            XCTFail("\(identifier) at \(frame) lies under the keyboard at \(keyboard.frame): a tap would land on the keyboard",
                    file: file, line: line)
            return
        }
        let at = frame
        tap()
        let deadline = Date().addingTimeInterval(2)
        while isOn != on && Date() < deadline { Thread.sleep(forTimeInterval: 0.2) }
        if isOn != on {
            XCTFail("\(identifier) did not turn \(on ? "on" : "off") after one tap; frame \(at), value \(String(describing: value)); "
                    + "hittable: \(isHittable); covered by " + app.whatCovers(self), file: file, line: line)
        }
    }

    var isOn: Bool { (value as? String) == "1" || (value as? Int) == 1 || (value as? Bool) == true }

    // MARK: Waits that say what they saw
    //
    // Every wait in these tests is a series of looks (`Looks.until`): one snapshot of the element each, a quarter
    // second apart, every look kept with what it saw and when. A failure lists them.
    //
    // XCTest's own waits (`XCTNSPredicateExpectation`, which `waitForExistence` uses too) are not used for anything a
    // test asserts. On GitHub's macOS arm64 runners one evaluation of theirs has taken 6 to 9 s, most of it XCUITest's
    // "Capturing element debug description", and the waiter gives up when its time runs out, whatever that evaluation
    // would have found, and says nothing of what was on screen:
    // - release run 44415519436: a 2 s `waitFor("Nothing touched")` made one look and failed while the screen showed
    //   "Nothing touched" (the screen recording); one existence check in the same test took 6.2 s;
    // - build run 44486580432: the care guide's 10 s `waitFor("Care guide loaded")` made one look, begun 2.2 s after the
    //   tap, which saw "Loading the care guide…" and then spent 8 s on the debug description. The page said "Care guide
    //   loaded" 5.4 to 5.7 s after the tap (the screen recording), and the wait never looked again.

    /// One look: what the element shows, in one query of the tree. A query that matches more than one element has no
    /// single snapshot (`app.alerts.buttons["Allow"]`); then a second query says whether anything matches.
    func glance() -> (now: XCUIElementSnapshot?, there: Bool) {
        if let now = try? snapshot() { return (now, true) }
        return (nil, exists)
    }

    static let several = "more than one element matches"

    /// Waits until the element's label or value contains `text` (as XCTest's `label CONTAINS %@ OR value CONTAINS %@`
    /// did), looking again and again for `timeout`, and keeps every look. Asserts nothing: `mustContain` asserts.
    func waitFor(_ text: String, timeout: TimeInterval = looksTimeout) -> Looks {
        Looks.until(timeout: timeout) {
            let (now, there) = glance()
            guard let now else { return (there ? Self.several : Self.absent, false) }
            let value = now.value as? String ?? ""
            return (Self.describe(now), now.label.contains(text) || value.contains(text))
        }
    }

    /// Waits until the element shows exactly `text` (its value for a field, otherwise its label).
    func looksUntil(shows text: String, timeout: TimeInterval) -> Looks {
        Looks.until(timeout: timeout) {
            let (now, there) = glance()
            guard let now else { return (there ? Self.several : Self.absent, false) }
            let shown = now.elementType == .textField || now.elementType == .secureTextField ? now.value as? String ?? "" : now.label
            return (shown, shown == text)
        }
    }

    /// Waits until the element is in the tree. A look is one `exists`, not a snapshot: a snapshot copies the element's
    /// whole subtree, and these are often whole screens.
    func appears(timeout: TimeInterval) -> Looks {
        Looks.until(timeout: timeout) { exists ? (Self.present, true) : (Self.absent, false) }
    }

    /// Waits until the element has left the tree; the failure says, after the looks, what it was and where.
    func vanishes(timeout: TimeInterval) -> Looks {
        Looks.until(timeout: timeout) { exists ? (Self.present, false) : (Self.absent, true) }
    }

    /// Fails unless the element's label or value comes to contain `text` within `timeout`; the failure lists every look:
    /// "<what>: never showed "<text>" in 10 s; the looks saw "…" at 0.0 s, …".
    @discardableResult
    func mustContain(_ text: String, timeout: TimeInterval = looksTimeout, _ what: String,
                     file: StaticString = #filePath, line: UInt = #line) -> Bool {
        waitFor(text, timeout: timeout).check("\(what): never showed \"\(text)\"", file: file, line: line)
    }

    /// Fails unless the element comes to show exactly `text` within `timeout`; the failure lists every look.
    @discardableResult
    func mustShow(_ text: String, timeout: TimeInterval = looksTimeout, _ what: String,
                  file: StaticString = #filePath, line: UInt = #line) -> Bool {
        looksUntil(shows: text, timeout: timeout).check("\(what): never showed \"\(text)\"", file: file, line: line)
    }

    /// Fails unless the element is in the tree within `timeout`; the failure lists the looks and the screen.
    @discardableResult
    func mustAppear(timeout: TimeInterval = looksTimeout, _ what: String, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        appears(timeout: timeout).check("\(what): never in the tree", withScreen: true, file: file, line: line)
    }

    /// Fails unless the element has left the tree within `timeout`; the failure lists every look and what it saw there.
    @discardableResult
    func mustVanish(timeout: TimeInterval = looksTimeout, _ what: String, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let looks = vanishes(timeout: timeout)
        let now = looks.met ? nil : glance().now
        return looks.check("\(what): still in the tree" + (now.map { " (\(Self.describe($0)) at \($0.frame))" } ?? ""),
                           withScreen: true, file: file, line: line)
    }

    static let absent = "nothing in the tree"
    static let present = "in the tree"

    /// A look in a line: the label, and the value when it says something the label does not.
    static func describe(_ now: XCUIElementSnapshot) -> String {
        let value = (now.value as? String).flatMap { $0.isEmpty || $0 == now.label ? nil : $0 }
            ?? (now.value as? NSNumber).map { "\($0)" }
        let label = now.label.isEmpty && value != nil ? "" : now.label
        return value.map { label.isEmpty ? "value \($0)" : "\(label) (value \($0))" } ?? label
    }
}

/// One look a wait made: what it saw, when it began and how long it took.
struct Look {
    let shown: String
    /// When the look began, from the wait's start.
    let after: TimeInterval
    /// How long it took to answer.
    let took: TimeInterval
    /// One line however many lines the element shows (the touch log shows up to three); a slow look says how long.
    var line: String {
        "\"\(shown.replacingOccurrences(of: "\n", with: " | "))\" at \(String(format: "%.1f", after)) s"
            + (took >= 1 ? String(format: " (a %.1f s look)", took) : "")
    }
}

/// Every look a wait made, in order, and whether it ended on one that saw what the wait was for.
struct Looks {
    let looks: [Look]
    let met: Bool
    let timeout: TimeInterval

    /// What the last look saw.
    var last: String? { looks.last?.shown }

    /// "in 10 s; the looks saw "…" at 0.0 s (a 6.2 s look), "…" at 6.5 s". Looks in a row that saw the same are one entry:
    /// ""nothing in the tree" in 31 looks from 0.0 s to 7.9 s (the longest 1.2 s)".
    var said: String {
        var runs: [[Look]] = []
        for look in looks {
            if let last = runs.last?.last, last.shown == look.shown { runs[runs.count - 1].append(look) } else { runs.append([look]) }
        }
        let lines = runs.map { run -> String in
            guard run.count > 1, let first = run.first, let last = run.last else { return run[0].line }
            let longest = run.map(\.took).max() ?? 0
            return "\"\(first.shown.replacingOccurrences(of: "\n", with: " | "))\" in \(run.count) looks from "
                + String(format: "%.1f s to %.1f s", first.after, last.after)
                + (longest >= 1 ? String(format: " (the longest %.1f s)", longest) : "")
        }
        return "in \(Self.seconds(timeout)) s; the looks saw " + lines.joined(separator: ", ")
    }

    /// Looks, a quarter second apart, until `look` says it saw what it waited for or `timeout` has passed since the
    /// first look began. A look that has begun is always finished and kept, however long it takes: a slow look is
    /// read, never given up on. So a wait always has at least one finished look, and its time is spent looking.
    @MainActor
    static func until(timeout: TimeInterval, _ look: () -> (shown: String, met: Bool)) -> Looks {
        let start = Date()
        var looks: [Look] = []
        while true {
            let began = Date().timeIntervalSince(start)
            let (shown, met) = look()
            looks.append(Look(shown: shown, after: began, took: Date().timeIntervalSince(start) - began))
            if met { return Looks(looks: looks, met: true, timeout: timeout) }
            if Date().timeIntervalSince(start) + 0.25 >= timeout { return Looks(looks: looks, met: false, timeout: timeout) }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    /// Fails with `what`, then every look, and (`withScreen`) the screens in the tree after the last look.
    @MainActor @discardableResult
    func check(_ what: String, withScreen: Bool = false, file: StaticString, line: UInt) -> Bool {
        guard !met else { return true }
        var text = "\(what) \(said)"
        if withScreen { text += "; then on screen: " + XCUIApplication().screens() }
        Misses.report(text, file: file, line: line)
        return false
    }

    static func seconds(_ time: TimeInterval) -> String {
        time == time.rounded() ? "\(Int(time))" : String(format: "%.1f", time)
    }
}

extension XCUIApplication {
    /// The `*_screen` ids in the tree now, and any alert or sheet over them.
    func screens() -> String {
        let screens = identifiers().filter { $0.hasSuffix("_screen") }
        let over = (alerts.allElementsBoundByIndex.map { "an alert \"\($0.label)\"" }
                    + sheets.allElementsBoundByIndex.map { "a sheet \"\($0.label)\"" })
        return (screens.isEmpty ? "no screen id" : screens.joined(separator: " "))
            + (over.isEmpty ? "" : "; over it " + over.joined(separator: ", "))
    }
}

extension XCUIApplication {
    /// What lies over `element`: the keyboard, a sheet or an alert in the app (iOS's "Save Password?" card is a sheet
    /// in the app's own tree), the banner, or nothing that the tree names.
    static let nothingNamed = "nothing the tree names"

    func whatCovers(_ element: XCUIElement) -> String {
        var found: [String] = []
        let keyboard = keyboards.firstMatch
        if keyboard.exists && keyboard.frame.intersects(element.frame) { found.append("the keyboard at \(keyboard.frame)") }
        // a sheet the element is inside (the date picker) is where it lives, not a cover
        for sheet in sheets.allElementsBoundByIndex where sheet.exists
            && !sheet.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", element.identifier)).firstMatch.exists {
            found.append("a sheet \"\(sheet.label)\" at \(sheet.frame)")
        }
        for alert in alerts.allElementsBoundByIndex where alert.exists {
            found.append("an alert \"\(alert.label)\" at \(alert.frame)")
        }
        let banner = id("snackbar")
        if banner.exists && banner.frame.intersects(element.frame) { found.append("the banner at \(banner.frame)") }
        return found.isEmpty ? Self.nothingNamed : found.joined(separator: "; ")
    }

    /// iOS's "Save Password?" card, if it is up: it lies over the whole screen until it is answered, and every tap
    /// beneath it misses. It is reported (the walk keeps it as a problem of the step that left it), then answered
    /// "Not Now", as a person answers it, so the screens after it are still checked.
    func answerSavePasswordCard(within wait: TimeInterval = 0, file: StaticString = #filePath, line: UInt = #line) {
        let card = descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Save Password?")).firstMatch
        // looked for, not waited for with XCTest's own wait: when the card is not there (nearly always), that wait's
        // failure costs XCUITest's debug capture, 9.7 s once (CI run 44388145174)
        guard wait > 0 ? card.appears(timeout: wait).met : card.exists else { return }
        Misses.report("iOS asked \"Save Password?\" over \(identifiers().filter { $0.hasSuffix("_screen") }.joined(separator: " ")); "
                      + "answered Not Now", file: file, line: line)
        let notNow = buttons["Not Now"].firstMatch
        if notNow.exists { notNow.tap() }
    }
}

/// How long a wait looks for something that should already be there, or come within a second: a screen after a tap,
/// a status after a gesture, the touch log after a tap or after a step that must touch nothing.
///
/// 10 s because of what one look has cost on GitHub's macOS arm64 runners: 6.2 s (an existence check in
/// `testSavedComesLateUIKit`, release run 44415519436, 49.95 to 56.16 s), 9.2 s (the care guide's one look, build run
/// 44486580432, 20.04 to 29.27 s, nearly all of it XCUITest's debug capture, which `Looks` does not make) and 3.8 s
/// (run 44388145174). A wait's timeout must hold the time the thing takes to come, plus one slow look that began just
/// before it came and missed it, plus the look after: what comes within a second is read by 1 + 6.2 + 0.25 s, about
/// 7.5 s. It costs nothing when the check passes: the looks stop at the first that sees it.
///
/// Something that comes after a known time waits that time plus this: `slowLoad + looksTimeout`, `careGuideTimeout`.
let looksTimeout: TimeInterval = 10

/// A slow load's wait, `LoadPlan.slowSeconds` in MossgroveKit (the UI tests do not link it): the delivery slots, and
/// any list with Settings › Slow loading on.
let slowLoad: TimeInterval = 3

/// How long the care guide gets to say "Care guide loaded" after its bench is tapped.
///
/// The bundled page has been seen to load late on CI's runners, though it loads nothing from the network. In build run
/// 44486580432 it said "Care guide loaded" 5.4 to 5.7 s after the tap (light screenshots, the screen recording: the tap's
/// event at 17.85 to 18.18 s, the last "Loading the care guide…" frame at 23.52 s, "loaded" at 23.54 s). In the same run
/// the dark screenshots saw it loading about 3.2 s after the tap and loaded by 8.2 s; Flows test 07, loading at about 4.0 s and
/// loaded by 7.9 s. So 8.2 s for the page, plus `looksTimeout` for a slow look in flight when it loads and the look
/// after, rounded up: 20 s. Until now it was 10 s, the whole of which one XCTest look could take.
let careGuideTimeout: TimeInterval = 20

/// The system's notification prompt, which Springboard draws. Allows it if it is there.
func allowNotificationsIfAsked() {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let allow = springboard.alerts.buttons["Allow"]
    if allow.appears(timeout: 8).met { allow.tap() }
}

import XCTest
@testable import MossgroveKit

final class CatalogTests: XCTestCase {
    func testFortyItemsInOrder() {
        XCTAssertEqual(Catalog.items.count, 40)
        XCTAssertEqual(Catalog.items.map(\.id), Array(1...40))
        XCTAssertEqual(Catalog.find(1)?.name, "Stoneware Mug")
        XCTAssertEqual(Catalog.find(40)?.name, "Fruit Bowl")
        XCTAssertNil(Catalog.find(0))
        XCTAssertNil(Catalog.find(41))
    }

    func testNumbersAndPrices() {
        XCTAssertEqual(itemNumber(7), "No. 007")
        XCTAssertEqual(Catalog.find(40)?.number, "No. 040")
        XCTAssertEqual(formatPrice(1400), "$14.00")
        XCTAssertEqual(formatPrice(950), "$9.50")
        XCTAssertEqual(formatPrice(8900), "$89.00")
        XCTAssertEqual(Catalog.find(25)?.price, "$89.00")
    }

    func testSearch() {
        XCTAssertEqual(Catalog.search("").count, 40)
        XCTAssertEqual(Catalog.search("   ").count, 40)
        XCTAssertEqual(Catalog.search("lamp").map(\.id), [5, 15, 25, 35])
        XCTAssertEqual(Catalog.search("LAMP").count, 4)
        XCTAssertEqual(Catalog.search("7").map(\.name), ["Wall Clock"])
        XCTAssertEqual(Catalog.search("007").map(\.id), [7])
        XCTAssertEqual(Catalog.search("No. 007").map(\.id), [7])
        XCTAssertEqual(Catalog.search("no. 7").map(\.id), [7])
        XCTAssertTrue(Catalog.search("velvet").isEmpty)
        XCTAssertEqual(Catalog.search("bowl").count, 4)
    }

    func testCountLine() {
        XCTAssertEqual(Catalog.countLine(query: "", results: 40), "40 drawers · No. 001–040")
        XCTAssertEqual(Catalog.countLine(query: "lamp", results: 4), "4 of 40 drawers")
    }

    func testFindRaw() {
        XCTAssertEqual(Catalog.find(raw: "7")?.name, "Wall Clock")
        XCTAssertNil(Catalog.find(raw: "999"))
        XCTAssertNil(Catalog.find(raw: "abc"))
    }
}

final class CartTests: XCTestCase {
    func testLinesKeepFirstAddedOrderAndCapAtNine() {
        var cart = Cart()
        cart.add(1, quantity: 2)
        cart.add(5, quantity: 1)
        cart.add(1, quantity: 9)
        XCTAssertEqual(cart.lines.map(\.itemId), [1, 5])
        XCTAssertEqual(cart.quantity(of: 1), 9)
        XCTAssertEqual(cart.itemCount, 10)
    }

    func testTotalsAndStepper() {
        var cart = Cart()
        cart.add(1, quantity: 2)
        XCTAssertEqual(formatPrice(cart.totalCents), "$28.00")
        cart.add(5, quantity: 1)
        XCTAssertEqual(formatPrice(cart.totalCents), "$70.00")
        cart.setQuantity(5, 0)
        XCTAssertEqual(cart.quantity(of: 5), 1, "the stepper's minimum is 1")
        cart.setQuantity(5, 12)
        XCTAssertEqual(cart.quantity(of: 5), 9)
        cart.remove(1)
        cart.setQuantity(5, 1)
        XCTAssertEqual(formatPrice(cart.totalCents), "$42.00")
        XCTAssertEqual(checkoutText(cart), "1 item · $42.00. This is a sample shop: nothing is charged or shipped.")
        cart.clear()
        XCTAssertTrue(cart.isEmpty)
    }

    func testOrderSummary() {
        var cart = Cart()
        cart.add(1, quantity: 1)
        cart.add(5, quantity: 1)
        let order = Order(number: 1, lines: cart.lines)
        XCTAssertEqual(order.summary, "2 items · Stoneware Mug, Brass Desk Lamp")
        XCTAssertEqual(formatPrice(order.totalCents), "$56.00")
        XCTAssertEqual(Texts.orderPlaced(1), "Order 1 placed")
    }

    func testAccount() {
        XCTAssertTrue(Account.matches(email: "  Tester@Mossgrove.TEST ", password: "Mossgrove123"))
        XCTAssertFalse(Account.matches(email: "tester@mossgrove.test", password: "mossgrove123"))
        XCTAssertEqual(Account.signInError(email: "", password: ""), "Enter your email and password")
        XCTAssertEqual(Account.signInError(email: "tester@mossgrove.test", password: "letmein1"), "Wrong email or password")
        XCTAssertNil(Account.signInError(email: "tester@mossgrove.test", password: "Mossgrove123"))
    }

    func testGiftCards() {
        XCTAssertEqual(GiftCards.check("MOSS-0025"), "Balance: $25.00")
        XCTAssertEqual(GiftCards.check("MOSS-9999"), "We don't recognise that code")
        XCTAssertEqual(GiftCards.choice(amount: 25, design: nil), "Choose a design")
        XCTAssertEqual(GiftCards.choice(amount: 50, design: "Stone"), "A $50 card with the Stone design")
    }
}

final class FormRulesTests: XCTestCase {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func testAnEmptyFormHasEveryError() {
        let errors = FormRules.errors(ClubForm())
        XCTAssertEqual(Set(errors.keys), Set(FormField.allCases))
        XCTAssertEqual(errors[.name], "Enter your name")
        XCTAssertEqual(errors[.email], "Enter a valid email address")
        XCTAssertEqual(errors[.age], "Enter an age from 18 to 120")
        XCTAssertEqual(errors[.password], "Use at least 8 characters, including a number")
        XCTAssertEqual(errors[.category], "Choose a favourite aisle")
        XCTAssertEqual(errors[.date], "Choose a delivery date")
        XCTAssertEqual(errors[.terms], "Accept the terms to continue")
    }

    func testEachRule() {
        var form = ClubForm()
        form.email = "sam@example"
        XCTAssertNotNil(FormRules.errors(form)[.email])
        form.email = "sam@example.test"
        XCTAssertNil(FormRules.errors(form)[.email])
        for (age, ok) in [("17", false), ("18", true), ("120", true), ("121", false), ("", false)] {
            form.age = age
            XCTAssertEqual(FormRules.errors(form)[.age] == nil, ok, age)
        }
        for (password, ok) in [("garden42x", true), ("gardenxyz", false), ("abc1", false)] {
            form.password = password
            XCTAssertEqual(FormRules.errors(form)[.password] == nil, ok, password)
        }
        XCTAssertEqual(FormRules.ageInput("3a4x56"), "345")
    }

    func testAValidJoin() throws {
        var form = ClubForm()
        form.name = "Sam Rivera"
        form.email = "sam@example.test"
        form.age = "34"
        form.password = "garden42x"
        form.aisle = .garden
        form.deliveryDate = try XCTUnwrap(utc.date(from: DateComponents(year: 2026, month: 11, day: 15, hour: 12)))
        form.acceptedTerms = true
        XCTAssertTrue(FormRules.errors(form).isEmpty)
        XCTAssertEqual(
            FormRules.welcome(form, calendar: utc),
            "Welcome, Sam Rivera. We'll write to sam@example.test about the Garden aisle and deliver on 15 Nov 2026."
        )
    }

    func testBudget() {
        XCTAssertEqual(FormRules.budgetText(50), "$50")
        XCTAssertEqual(FormRules.budgetText(0.6 * 200), "$120")
        XCTAssertEqual(FormRules.budgetRange, 0...200)
        XCTAssertEqual(FormRules.budgetStep, 10)
    }
}

final class DeepLinkTests: XCTestCase {
    func testItemLinks() {
        XCTAssertEqual(DeepLinks.itemId(URL(string: "nthcase-sample://item/7")!), "7")
        XCTAssertEqual(DeepLinks.itemId(URL(string: "nthcase-sample://item/999")!), "999")
        XCTAssertEqual(DeepLinks.itemId(URL(string: "nthcase-sample://item/abc")!), "abc")
        XCTAssertEqual(DeepLinks.forItem(7).absoluteString, "nthcase-sample://item/7")
    }

    func testOtherLinksAreIgnored() {
        for link in ["nthcase-sample://cart/7", "nthcase-sample://item", "nthcase-sample://item/", "nthcase-sample://item/7/8", "https://item/7"] {
            XCTAssertNil(DeepLinks.itemId(URL(string: link)!), link)
        }
    }
}

final class GestureTests: XCTestCase {
    func testSwipeDirection() {
        XCTAssertEqual(GestureRules.swipeDirection(dx: -120, dy: 10), .left)
        XCTAssertEqual(GestureRules.swipeDirection(dx: 120, dy: -30), .right)
        XCTAssertEqual(GestureRules.swipeDirection(dx: 20, dy: -90), .up)
        XCTAssertEqual(GestureRules.swipeDirection(dx: 5, dy: 60), .down)
        XCTAssertNil(GestureRules.swipeDirection(dx: 30, dy: 30), "under 48 points is not a swipe")
        XCTAssertEqual(GestureWords.swiped(.left), "Swiped left")
    }

    func testPinchAndRotation() {
        XCTAssertEqual(GestureRules.pinchWord(scale: 1.5), "Pinched out")
        XCTAssertEqual(GestureRules.pinchWord(scale: 0.5), "Pinched in")
        XCTAssertNil(GestureRules.pinchWord(scale: 1.04))
        XCTAssertEqual(GestureRules.zoom(after: 2, scale: 2), 3)
        XCTAssertEqual(GestureWords.zoom(1), "Zoom 1.0×")
        XCTAssertEqual(GestureWords.zoom(1.5), "Zoom 1.5×")
        XCTAssertEqual(GestureRules.rotationWord(degrees: 45), "Rotated clockwise")
        XCTAssertEqual(GestureRules.rotationWord(degrees: -45), "Rotated counter-clockwise")
        XCTAssertNil(GestureRules.rotationWord(degrees: 9))
        XCTAssertEqual(GestureWords.rotation(0), "Rotation 0°")
        XCTAssertEqual(GestureWords.rotation(GestureRules.rotation(after: 350, degrees: 45)), "Rotation 35°")
        XCTAssertEqual(GestureWords.taps(3), "Taps: 3")
    }

    func testShakeNeedsThreeJoltsWithinASecond() {
        var shakes = 0
        let detector = ShakeDetector { shakes += 1 }
        detector.onReading(x: 0, y: 1, z: 0, time: 0)
        detector.onReading(x: 3, y: 0, z: 0, time: 0.1)
        detector.onReading(x: 0, y: 3, z: 0, time: 0.4)
        XCTAssertEqual(shakes, 0)
        detector.onReading(x: 0, y: 0, z: 3, time: 0.8)
        XCTAssertEqual(shakes, 1)
        // spread over more than a second: not a shake
        detector.onReading(x: 3, y: 0, z: 0, time: 2.0)
        detector.onReading(x: 3, y: 0, z: 0, time: 2.6)
        detector.onReading(x: 3, y: 0, z: 0, time: 3.3)
        XCTAssertEqual(shakes, 1)
        detector.onSystemShake()
        XCTAssertEqual(shakes, 2)
    }
}

final class NavigationTests: XCTestCase {
    /// SPEC.md §4: a tab always opens at its first screen, and reselecting a tab returns it to its root.
    func testReselectingATabResetsItToItsRoot() {
        var nav = TabNavigation()
        nav.select(.lab)
        nav.push(.gestures)
        XCTAssertEqual(nav.path(.lab), [.gestures])
        nav.select(.lab)
        XCTAssertEqual(nav.path(.lab), [])
        XCTAssertEqual(nav.selected, .lab)
    }

    func testATabNeverRestoresADeeperScreen() {
        var nav = TabNavigation()
        nav.push(.item("1"))
        nav.select(.cart)
        nav.select(.shop)
        XCTAssertEqual(nav.path(.shop), [], "the item from the earlier visit is gone")
        nav.select(.settings)
        nav.push(.orders)
        nav.select(.lab)
        nav.select(.settings)
        XCTAssertEqual(nav.path(.settings), [])
    }

    func testBackPopsOneScreen() {
        var nav = TabNavigation()
        nav.select(.lab)
        nav.push(.form)
        nav.setPath([], for: .lab)
        XCTAssertEqual(nav.path(.lab), [])
        nav.push(.orders)
        nav.pop()
        XCTAssertEqual(nav.path(.lab), [])
    }

    func testADeepLinkOpensOnTheShopTab() {
        var nav = TabNavigation()
        nav.select(.settings)
        nav.push(.orders)
        nav.openItem("7")
        XCTAssertEqual(nav.selected, .shop)
        XCTAssertEqual(nav.path(.shop), [.item("7")])
        nav.pop()
        XCTAssertEqual(nav.path(.shop), [], "Back lands on the Shop")
        nav.reset()
        XCTAssertEqual(nav, TabNavigation())
    }

    func testCartTabLabel() {
        XCTAssertEqual(cartTabLabel(count: 0), "Cart")
        XCTAssertEqual(cartTabLabel(count: 1), "Cart, 1 item")
        XCTAssertEqual(cartTabLabel(count: 2), "Cart, 2 items")
    }

    func testLoadPlan() {
        XCTAssertEqual(LoadPlan.first(slow: false, fail: false, attempt: 0), .ready)
        XCTAssertEqual(LoadPlan.first(slow: true, fail: false, attempt: 0), .loading)
        XCTAssertEqual(LoadPlan.first(slow: false, fail: true, attempt: 0), .failed)
        XCTAssertEqual(LoadPlan.first(slow: false, fail: true, attempt: 1), .ready, "Try again succeeds")
        XCTAssertEqual(LoadPlan.afterWait(fail: true, attempt: 0), .failed)
        XCTAssertEqual(LoadPlan.slowSeconds, 3)
    }

    func testNotificationStatus() {
        XCTAssertEqual(Texts.notificationStatus(allowed: false, on: false), "Not allowed. Turn this on to be asked.")
        XCTAssertEqual(Texts.notificationStatus(allowed: true, on: false), "Off")
        XCTAssertEqual(Texts.notificationStatus(allowed: true, on: true), "On: we'll tell you when an order is placed.")
        XCTAssertEqual(Texts.version("1.0.0"), "Mossgrove 1.0.0 · spec 1.0 · a sample app for NthCase")
    }
}

/// A hidden password keeps what was typed when a new editing session begins (the second CI run: "garden42x" kept
/// only "x").
final class PasswordEditingTests: XCTestCase {
    private func key(_ text: String, _ location: Int, _ length: Int, _ replacement: String, fresh: Bool) -> String {
        PasswordEditing.apply(to: text, range: NSRange(location: location, length: length), replacement: replacement, sessionJustBegan: fresh)
    }

    func testTypingAddsAtTheCursor() {
        XCTAssertEqual(key("", 0, 0, "g", fresh: true), "g")
        XCTAssertEqual(key("garden4", 7, 0, "2", fresh: false), "garden42")
        XCTAssertEqual(key("garden42", 8, 0, "x", fresh: true), "garden42x")
        XCTAssertEqual(key("garden42x", 8, 1, "", fresh: false), "garden42")
        XCTAssertEqual(key("garden42", 0, 8, "", fresh: false), "", "Delete on a selection that is all of it, mid-session")
    }

    /// UIKit's way of emptying a secure field: the first key of a session replaces all of it.
    func testANewSessionKeepsTheText() {
        XCTAssertEqual(key("garden42", 0, 8, "x", fresh: true), "garden42x")
        XCTAssertEqual(key("garden42", 0, 8, "", fresh: true), "garden4", "Delete removes one character, not all")
        XCTAssertEqual(key("a", 0, 1, "", fresh: true), "")
        XCTAssertEqual(key("Mossgrove12", 0, 11, "3", fresh: true), "Mossgrove123")
    }

    func testARangeOutsideTheTextAddsAtTheEnd() {
        XCTAssertEqual(key("abc", 5, 0, "d", fresh: false), "abcd")
        XCTAssertEqual(PasswordEditing.apply(to: "abc", range: NSRange(location: NSNotFound, length: 0), replacement: "d", sessionJustBegan: false), "abcd")
    }
}

/// The budget slider: $0–200 in $10 steps (SPEC.md §5), set the way NthCase's `slide` and the flows set it.
final class SliderTrackTests: XCTestCase {
    private let range = FormRules.budgetRange
    private let step = FormRules.budgetStep
    /// The form's slider in the fourth CI run: 370 points wide at x 16 on a 402-point iPhone, a 37-point thumb.
    private let minX = 16.0, maxX = 386.0

    private func dollars(_ fraction: Double) -> Double {
        SliderTrack.snapped(range.lowerBound + fraction * (range.upperBound - range.lowerBound), range: range, step: step)
    }

    /// The six slides of `testTheBudgetLandsWhereSlideSetsIt`, each from where the one before left the slider.
    private func slides(low: Double, high: Double, push: Double = 0) -> [Double] {
        var value = 50.0
        return [0.6, 0.3, 1.0, 0.0, 0.45, 0.6].map { target in
            let from = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            value = dollars(SliderTrack.xcuiDrag(from: from, to: target, minX: minX, maxX: maxX, low: low, high: high, push: push))
            return value
        }
    }

    /// XCUITest's touch points, as the fourth CI run recorded them: from $50 (0.25) it pressed at 112.12 and lifted
    /// at 236.55 for 0.6; the ends are 23.25 and 378.75.
    func testXCUITestTouchesWhereTheRunRecorded() {
        XCTAssertEqual(SliderTrack.xcuiTouch(fraction: 0.25, minX: minX, maxX: maxX), 112.125, accuracy: 0.001)
        XCTAssertEqual(SliderTrack.xcuiTouch(fraction: 0.6, minX: minX, maxX: maxX), 236.55, accuracy: 0.001)
        XCTAssertEqual(SliderTrack.xcuiTouch(fraction: 0.0, minX: minX, maxX: maxX), 23.25, accuracy: 0.001)
        XCTAssertEqual(SliderTrack.xcuiTouch(fraction: 1.0, minX: minX, maxX: maxX), 378.75, accuracy: 0.001)
        XCTAssertEqual(SliderTrack.xcuiTouch(fraction: 0.65, minX: minX, maxX: maxX), 254.325, accuracy: 0.001)
    }

    /// The fourth run read $130, $50, $200, $0, $100, $130. UIKit's own track (thumb centre 18.5 points inside each
    /// end) explains only the $100; all six need the thumb carried 6–15 points past the finger in the drag's
    /// direction, which a lift at 500 points a second gives. Neither alone is the run.
    func testTheFourthRunIsUIKitsTrackPlusAPushPastTheFinger() {
        let low = minX + 18.5, high = maxX - 18.5
        XCTAssertEqual(slides(low: low, high: high), [120, 60, 200, 0, 100, 120], "the track alone")
        XCTAssertEqual(slides(low: low, high: high, push: 10), [130, 50, 200, 0, 100, 130], "the track and a push")
        XCTAssertNotEqual(slides(low: low, high: high, push: 3), [130, 50, 200, 0, 100, 130])
    }

    /// The app's thumb has its centre where XCUITest presses, and the value follows the finger alone: every step
    /// lands from every start.
    func testOnTheAppsTrackEveryStepLandsFromEveryStart() {
        let low = minX + Double(SliderTrack.xcuiInset), high = maxX - Double(SliderTrack.xcuiInset)
        XCTAssertEqual(slides(low: low, high: high), [120, 60, 200, 0, 90, 120])
        for start in 0...20 {
            for target in 0...20 {
                let landed = SliderTrack.xcuiDrag(from: Double(start) / 20, to: Double(target) / 20, minX: minX, maxX: maxX,
                                                  low: low, high: high)
                XCTAssertEqual(dollars(landed), Double(target * 10), "from $\(start * 10) to \(Double(target) / 20)")
            }
        }
    }

    /// UIKit's thumb travels from half its width inside each end of the track, which is where UIKit puts the
    /// scrubbers: a 14.5-point thumb's centre is where XCUITest presses, at both ends, on any track.
    func testTheAppsThumbIsAsWideAsXCUITestAssumes() {
        XCTAssertEqual(SliderTrack.xcuiThumbWidth, 14.5)
        for (minX, maxX) in [(16.0, 386.0), (0.0, 348.0), (27.0, 375.0)] {
            XCTAssertEqual(minX + SliderTrack.xcuiThumbWidth / 2, SliderTrack.xcuiTouch(fraction: 0, minX: minX, maxX: maxX), accuracy: 0.0001)
            XCTAssertEqual(maxX - SliderTrack.xcuiThumbWidth / 2, SliderTrack.xcuiTouch(fraction: 1, minX: minX, maxX: maxX), accuracy: 0.0001)
        }
    }

    /// A finger that comes down on the thumb off its centre moves it by the finger's travel, not to the finger.
    func testAThumbHeldOffCentreDoesNotJump() {
        XCTAssertEqual(SliderTrack.fraction(fingerX: 106, grab: 6, low: 10, high: 190), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SliderTrack.fraction(fingerX: 100, grab: 0, low: 10, high: 190), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SliderTrack.fraction(fingerX: -40, grab: 0, low: 10, high: 190), 0)
        XCTAssertEqual(SliderTrack.fraction(fingerX: 400, grab: 0, low: 10, high: 190), 1)
        XCTAssertEqual(SliderTrack.fraction(fingerX: 50, grab: 0, low: 10, high: 10), 0, "no travel")
    }

    func testEveryValueIsAStepInTheRange() {
        XCTAssertEqual(SliderTrack.snapped(122, range: range, step: step), 120)
        XCTAssertEqual(SliderTrack.snapped(125, range: range, step: step), 130, "halfway rounds up")
        XCTAssertEqual(SliderTrack.snapped(127.4, range: range, step: step), 130)
        XCTAssertEqual(SliderTrack.snapped(-3, range: range, step: step), 0)
        XCTAssertEqual(SliderTrack.snapped(204, range: range, step: step), 200)
        XCTAssertEqual(FormRules.budgetText(SliderTrack.snapped(119.6, range: range, step: step)), "$120")
    }

    func testTheTravelRunsFromCentreToCentre() {
        let travel = SliderTrack.travel(lowCentre: 14, highCentre: 356, height: 44)
        XCTAssertEqual(travel, CGRect(x: 14, y: 0, width: 342, height: 44))
        XCTAssertEqual(SliderTrack.travel(lowCentre: 10, highCentre: 10, height: 30).width, 1, "never zero wide")
    }
}

import XCTest

/// The flows of scenarios 01–10 (`nthcase/scenarios/`), step for step, plus the rules SPEC.md §4 and §5 add: a tab
/// opens at its first screen, the edge swipe goes back, and the deep links of scenario 11.
///
/// They play the scenarios as NthCase does: typing presses no Return unless the scenario says so (there is no
/// hide-keyboard step, SPEC.md §13), so every later tap is made with the keyboard up; and the tab bar is on the tabs'
/// first screens only, as on Android, so a scenario's "Open the Cart tab" from an item page is Back, then the tab.
final class FlowTests: XCTestCase {
    private var app: XCUIApplication!

    /// A flow goes on after a check fails, so one run reports every step that fails, not the first: in the fourth CI
    /// run flow 04 stopped at the newsletter and said nothing of its budget, terms and Join. A tap on an element that
    /// never came is reported and skipped (`tapWhenThere`), so the steps after it are still tried.
    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    private func expect(_ text: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.text(text).waitForExistence(timeout: timeout), "the screen does not show \"\(text)\"", file: file, line: line)
    }

    private func expect(_ id: String, shows text: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let element = app.id(id)
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(id) is not on screen", file: file, line: line)
        XCTAssertTrue(element.waitFor(text, timeout: timeout), "\(id) shows \"\(element.shown)\", not \"\(text)\"", file: file, line: line)
    }

    // 01 · Sign in with the test account
    func test01SignIn() {
        expect("Mossgrove")
        expect("Home and desk goods")
        app.id("signin_email").type("tester@mossgrove.test")
        app.id("signin_password").type("letmein1")
        app.id("signin_submit").tapWhenThere()
        expect("Wrong email or password")
        app.id("signin_password_toggle").tapWhenThere()
        expect("signin_password", shows: "letmein1")
        app.id("signin_password").replace(with: "Mossgrove123")
        app.id("signin_submit").tapWhenThere()
        expect("shop_item_1", shows: "Stoneware Mug")
        expect("shop_count", shows: "40 drawers")
    }

    // 02 · Search, scroll and refresh the shop
    func test02SearchAndScroll() {
        app.signIn()
        app.id("shop_search").type("lamp\n")
        expect("shop_count", shows: "4 of 40 drawers")
        expect("shop_item_25", shows: "Floor Lamp")
        app.id("shop_search_clear").tapWhenThere()
        expect("shop_count", shows: "40 drawers")
        app.id("shop_search").type("velvet\n")
        expect("No drawers match")
        XCTAssertTrue(app.buttons["Clear search"].exists)
        app.id("shop_empty_action").tapWhenThere()
        let last = app.scrollTo(app.id("shop_item_40"))
        XCTAssertTrue(last.waitFor("Fruit Bowl"))
        XCTAssertTrue(last.waitFor("No. 040"))
        app.scrollTo(app.id("shop_item_1"), up: true)
        app.scrollTo(app.id("shop_search"), up: true)
        pullToRefresh(app)
        expect("snackbar_text", shows: "Catalogue is up to date", timeout: 8)
        app.id("shop_search").type("7\n")
        expect("shop_count", shows: "1 of 40 drawers")
        expect("shop_item_7", shows: "Wall Clock")
        XCTAssertFalse(app.id("shop_item_1").exists)
    }

    // 03 · Fill the cart and place an order
    func test03CartAndOrder() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        expect("item_number", shows: "No. 001")
        expect("item_price", shows: "$14.00")
        app.id("item_qty_increase").tapWhenThere()
        expect("item_qty_value", shows: "2")
        app.id("item_add_to_cart").tapWhenThere()
        expect("snackbar_text", shows: "Added to cart")
        app.id("snackbar_action").tapWhenThere()
        expect("cart_total", shows: "$28.00")
        app.openTab("nav_shop")
        app.scrollTo(app.id("shop_item_5")).tapWhenThere()
        app.id("item_add_to_cart").tapWhenThere()
        app.back()
        app.openTab("nav_cart")
        expect("cart_total", shows: "$70.00")
        app.id("cart_line_remove_1").tapWhenThere()
        XCTAssertTrue(app.id("cart_line_1").waitToVanish())
        expect("cart_total", shows: "$42.00")
        let orderTotal = app.id("cart_total").label
        checkOutIsFree()
        app.id("cart_checkout").tapWhenThere()
        expect("dialog_title", shows: "Place this order?")
        app.id("dialog_dismiss").tapWhenThere()
        XCTAssertTrue(app.id("dialog").waitToVanish())
        expect("Brass Desk Lamp")
        app.id("cart_checkout").tapWhenThere()
        app.id("dialog_confirm").tapWhenThere()
        expect("snackbar_text", shows: "Order 1 placed")
        expect("Your cart is empty")
        app.id("snackbar_action").tapWhenThere()
        expect("orders_row_1", shows: "Order 1")
        expect("orders_row_1", shows: orderTotal)
    }

    // 04 · Join the club: every form control
    func test04Form() {
        app.signIn()
        app.openLab("lab_form")
        app.scrollTo(app.id("form_submit")).tapWhenThere()
        for error in ["Enter your name", "Enter a valid email address", "Enter an age from 18 to 120", "Accept the terms to continue"] {
            XCTAssertTrue(app.text(error).exists, "no \"\(error)\"")
        }
        app.scrollTo(app.id("form_name"), up: true).type("Sam Rivera")
        app.id("form_email").type("sam@example")
        expect("Enter a valid email address")
        app.id("form_email").type(".test")
        XCTAssertTrue(app.id("form_email_error").waitToVanish())
        app.id("form_age").type("34")
        app.id("form_password").type("garden42x")
        app.id("form_password_toggle").tapWhenThere()
        expect("form_password", shows: "garden42x")
        app.scrollTo(app.id("form_category")).tapWhenThere()
        app.id("form_category_option_garden").tapWhenThere()
        // Moving on from the password to the aisle puts the keyboard away: in the fourth CI run it stayed up, over the
        // newsletter switch, and both taps on the switch landed on it.
        XCTAssertTrue(app.keyboards.firstMatch.waitToVanish(timeout: 3), "the keyboard stayed up after choosing an aisle")
        app.scrollTo(app.id("form_date")).tapWhenThere()
        let picker = app.id("form_date_picker")
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        let fifteen = picker.buttons.matching(NSPredicate(format: "label ENDSWITH ' 15' OR label == '15'")).firstMatch
        (fifteen.exists ? fifteen : picker.staticTexts["15"]).tap()
        app.id("form_date_confirm").tapWhenThere()
        expect("15 ")
        app.scrollTo(app.id("form_newsletter")).set(true)
        // as NthCase's slide sets it: WebDriverAgent sets a slider's value with this very call
        XCTAssertEqual(app.id("form_budget").elementType, .slider, "form_budget is not a slider to Appium")
        app.id("form_budget").adjust(toNormalizedSliderPosition: 0.6)
        expect("form_budget_value", shows: "$120")
        app.scrollTo(app.id("form_terms")).tapWhenThere()
        app.scrollTo(app.id("form_submit")).tapWhenThere()
        expect("Welcome, Sam Rivera")
        expect("Garden aisle")
        expect("snackbar_text", shows: "Welcome to the club")
    }

    // 05 · Every gesture on the Gestures screen
    func test05Gestures() {
        app.signIn()
        app.openLab("lab_gestures")
        let status = app.id("gestures_status")
        expect("gestures_status", shows: "Ready")
        app.id("gestures_tap").tapWhenThere()
        XCTAssertTrue(status.waitFor("Tapped"))
        expect("gestures_tap_count", shows: "Taps: 1")
        app.id("gestures_double_tap").doubleTap()
        XCTAssertTrue(status.waitFor("Double-tapped"))
        app.id("gestures_long_press").press(forDuration: 1.0)
        XCTAssertTrue(status.waitFor("Long-pressed"))
        let swipe = app.id("gestures_swipe")
        swipe.swipeLeft()
        XCTAssertTrue(status.waitFor("Swiped left"))
        swipe.swipeRight()
        XCTAssertTrue(status.waitFor("Swiped right"))
        swipe.swipeUp()
        XCTAssertTrue(status.waitFor("Swiped up"))
        swipe.swipeDown()
        XCTAssertTrue(status.waitFor("Swiped down"))
        app.id("gestures_drag_source").press(forDuration: 0.5, thenDragTo: app.id("gestures_drop_target"))
        XCTAssertTrue(status.waitFor("Dropped on the drawer"))
        app.scrollTo(app.id("gestures_pinch")).pinch(withScale: 2.0, velocity: 1.0)
        XCTAssertTrue(status.waitFor("Pinched out"))
        // not in the scenario (NthCase has no two-finger rotation yet), but the pad works
        app.id("gestures_rotate").rotate(.pi / 2, withVelocity: 1.0)
        XCTAssertTrue(status.waitFor("Rotated"))
        app.scrollTo(app.id("gestures_scroll_target")).tapWhenThere()
        XCTAssertTrue(status.waitFor("Found the bottom drawer"))
    }

    // 06 · The device: rotate, home, back. Lock and unlock have no XCUITest call; shake has none either (ShakeTests).
    func test06Device() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        app.id("item_add_to_cart").tapWhenThere()
        app.back()
        app.openLab("lab_gestures")
        expect("gestures_orientation", shows: "Portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        expect("gestures_orientation", shows: "Landscape")
        XCUIDevice.shared.orientation = .portrait
        expect("gestures_orientation", shows: "Portrait")
        app.back()
        expect("lab_form", shows: "Join the club")
        app.openTab("nav_cart")
        expect("Stoneware Mug")
        app.openTab("nav_shop")
        XCUIDevice.shared.press(.home)
        app.activate()
        expect("Mossgrove")
        if app.id("signin_submit").exists { app.signIn() }
        expect("Stoneware Mug")
    }

    // 07 · The care guide: a web page inside the app
    func test07WebView() {
        app.signIn()
        app.openLab("lab_webview")
        expect("webview_status", shows: "Care guide loaded", timeout: 10)
        let page = app.webViews.firstMatch
        let name = page.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5), "the page's Your name field")
        name.type("Sam")
        choose("Every week", in: page)
        let agree = page.descendants(matching: .any).matching(NSPredicate(format: "label == 'Email me the guide' AND elementType != %d", XCUIElement.ElementType.staticText.rawValue)).firstMatch
        XCTAssertTrue(agree.waitForExistence(timeout: 3), "the page's Email me the guide checkbox")
        agree.tap()
        page.buttons["Save"].tap()
        XCTAssertTrue(page.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Saved, Sam. We will remind you every week.'")).firstMatch.waitForExistence(timeout: 5))
        page.links["Jump to washing"].tap()
        XCTAssertTrue(page.staticTexts["Washing"].waitForExistence(timeout: 5))
    }

    // 08 · A slow screen, an error with retry, and empty states
    func test08SlowAndStates() {
        app.signIn()
        app.openLab("lab_slow")
        XCTAssertTrue(app.id("slow_slot_1").waitForExistence(timeout: 8))
        expect("Monday · 8:00–10:00")
        expect("Saturday · 10:00–12:00")
        app.back()
        app.id("lab_orders").tapWhenThere()
        expect("No orders yet")
        app.back()
        app.openTab("nav_settings")
        app.scrollTo(app.id("settings_fail_loading")).set(true)
        app.openLab("lab_orders")
        expect("Orders didn't load")
        app.id("orders_retry").tapWhenThere()
        expect("No orders yet")
        app.back()
        app.openTab("nav_settings")
        app.scrollTo(app.id("settings_fail_loading")).set(false)
        app.id("settings_slow_loading").set(true)
        app.openTab("nav_shop")
        XCTAssertTrue(app.id("shop_item_1").waitForExistence(timeout: 8))
        expect("Stoneware Mug")
        app.openTab("nav_cart")
        expect("Your cart is empty")
    }

    // 09 · Settings, the notification prompt and a confirm dialog
    func test09SettingsAndPermission() {
        app.signIn()
        app.openTab("nav_settings")
        expect("tester@mossgrove.test")
        let status = app.id("settings_notifications_status")
        let askedBefore = !status.waitFor("Not allowed. Turn this on to be asked.", timeout: 3)
        app.id("settings_theme_dark").tapWhenThere()
        XCTAssertTrue(app.id("settings_theme_dark").isSelected, "Dark is not selected")
        app.id("settings_theme_system").tapWhenThere()
        app.id("settings_notifications").tapWhenThere()
        if !askedBefore { allowNotificationsIfAsked() }
        XCTAssertTrue(status.waitFor("On: we'll tell you when an order is placed.", timeout: 8),
                      "status: \(status.label) (a refusal from an earlier run on this simulator stops the prompt)")
        app.id("settings_send_notification").tapWhenThere()
        expect("snackbar_text", shows: "Notification sent")
        app.scrollTo(app.id("settings_reset")).tapWhenThere()
        expect("Empty the cart and orders?")
        let cancel = app.id("settings_reset_cancel")
        (cancel.waitForExistence(timeout: 3) ? cancel : app.alerts.buttons["Cancel"]).tap()
        app.scrollTo(app.id("settings_sign_out"), up: true).tapWhenThere()
        expect("Test account")
    }

    // 10 · Gift cards: a screen with no test ids
    func test10NoTestIds() {
        app.signIn()
        app.openLab("lab_gift_cards")
        expect("Check a balance")
        let code = app.textFields["Card code"]
        code.type("MOSS-0025\n")
        app.buttons["Check balance"].tap()
        expect("Balance: $25.00")
        code.replace(with: "MOSS-9999\n")
        app.buttons["Check balance"].tap()
        expect("We don't recognise that code")
        app.buttons["$50"].tap()
        let choose = app.buttons.matching(NSPredicate(format: "label == 'Choose'")).allElementsBoundByIndex.sorted { $0.frame.minX < $1.frame.minX }
        XCTAssertEqual(choose.count, 2, "two buttons say Choose")
        choose.last?.tap()
        expect("A $50 card with the Stone design")
        choose.first?.tap()
        expect("A $50 card with the Fern design")
    }

    /// The page's "Remind me" list, chosen as NthCase can in the app's own tree: tap the control that shows the
    /// current choice (WebKit names it by its `<label>`, "Remind me", and its value is "Every month"), then tap the
    /// option in the menu iOS opens. On iOS 26 the control is not a pop-up button (second CI run: "Automation type
    /// mismatch: computed Other … vs WebView"), so it is found by what it says, of any type but static text. Both
    /// trees are kept in the result bundle, so a run that fails here shows how iOS drew the list.
    private func choose(_ option: String, in page: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let staticText = XCUIElement.ElementType.staticText.rawValue
        let control = page.descendants(matching: .any).matching(NSPredicate(
            format: "elementType != %d AND (value == 'Every month' OR label == 'Remind me' OR label == 'Every month')", staticText)).firstMatch
        keepTree(page, "the page before the list opens")
        XCTAssertTrue(control.waitForExistence(timeout: 5), "the page's Remind me list", file: file, line: line)
        control.tap()
        // the menu iOS opens: its rows are menu items, buttons or cells (a wheel, on an older iOS, has a Done button)
        let candidates = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", option))
        _ = candidates.firstMatch.waitForExistence(timeout: 3)
        keepTree(app, "the app after the list opened")
        let rows: [XCUIElement.ElementType] = [.menuItem, .button, .cell]
        let item = candidates.allElementsBoundByIndex.first { rows.contains($0.elementType) } ?? candidates.firstMatch
        XCTAssertTrue(item.exists, "the Remind me list did not offer \"\(option)\"", file: file, line: line)
        item.tap()
        if app.pickerWheels.firstMatch.exists { app.toolbars.buttons["Done"].firstMatch.tap() }
    }

    private func keepTree(_ element: XCUIElement, _ name: String) {
        XCTContext.runActivity(named: name) { activity in
            let tree = XCTAttachment(string: element.debugDescription)
            tree.name = name
            tree.lifetime = .keepAlways
            activity.add(tree)
        }
    }

    // 11 · Deep link to an item, as the scenario plays it: opened from outside on a cold start, so signed out
    func test11DeepLink() {
        app.openLinkFromColdStart("nthcase-sample://item/7")
        XCTAssertTrue(app.id("signin_screen").waitForExistence(timeout: 15), "a cold start shows sign-in first")
        app.signIn(expectShop: false)
        expect("item_name", shows: "Wall Clock", timeout: 8)
        expect("item_number", shows: "No. 007")
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
    }

    // 11 · The same link while the app runs and is signed in, from another tab; then an unknown id
    func test11DeepLinkWhileRunning() {
        app.signIn()
        app.openTab("nav_settings")
        XCTAssertTrue(app.id("settings_screen").waitForExistence(timeout: 5))
        app.openLinkWhileRunning("nthcase-sample://item/7")
        // a relaunch would show sign-in: this line names it
        XCTAssertFalse(app.id("signin_screen").waitForExistence(timeout: 2), "the link restarted the app: sign-in is on screen")
        expect("item_name", shows: "Wall Clock", timeout: 8)
        expect("item_number", shows: "No. 007")
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
        app.openLinkWhileRunning("nthcase-sample://item/999")
        XCTAssertFalse(app.id("signin_screen").exists, "the link restarted the app: sign-in is on screen")
        expect("No drawer has the number", timeout: 8)
    }

    // 11 · Signed out and running: sign-in first, then the item
    func test11DeepLinkSignedOutWhileRunning() {
        XCTAssertTrue(app.id("signin_screen").waitForExistence(timeout: 15))
        app.openLinkWhileRunning("nthcase-sample://item/7")
        XCTAssertTrue(app.id("signin_screen").waitForExistence(timeout: 5), "signed out, the link shows sign-in first")
        app.signIn(expectShop: false)
        expect("item_name", shows: "Wall Clock", timeout: 8)
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
    }

    /// SPEC.md §4: a tab always opens at its first screen. The bar is not on the screens below a tab, so a tab is
    /// left from below by the app's own ways to another tab (View cart, Start shopping), then chosen again.
    func testATabOpensAtItsFirstScreen() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        XCTAssertTrue(app.id("item_screen").waitForExistence(timeout: 5))
        XCTAssertFalse(app.id("nav_shop").exists, "the tab bar is on the item page")
        app.id("item_add_to_cart").tapWhenThere()
        app.id("snackbar_action").tapWhenThere()
        XCTAssertTrue(app.id("cart_screen").waitForExistence(timeout: 5))
        app.openTab("nav_shop")
        XCTAssertTrue(app.id("shop_screen").waitForExistence(timeout: 5))
        XCTAssertFalse(app.id("item_screen").exists, "Shop came back on the item")
        app.openLab("lab_orders")
        XCTAssertTrue(app.id("orders_empty_action").waitForExistence(timeout: 5))
        app.id("orders_empty_action").tapWhenThere()
        XCTAssertTrue(app.id("shop_screen").waitForExistence(timeout: 5))
        app.openTab("nav_lab")
        XCTAssertTrue(app.id("lab_screen").waitForExistence(timeout: 5))
        XCTAssertFalse(app.id("orders_screen").exists, "Lab came back on Orders")
        app.openTab("nav_lab")
        XCTAssertTrue(app.id("lab_screen").exists, "choosing Lab again left its first screen")
    }

    /// Check out is the element a tap reaches: if the banner is up, it is not over Check out. The third CI run's flow
    /// 03 tapped Check out with the Add-to-cart banner still up, and no dialog came.
    private func checkOutIsFree(file: StaticString = #filePath, line: UInt = #line) {
        let checkout = app.id("cart_checkout")
        XCTAssertTrue(checkout.waitForExistence(timeout: 5), "cart_checkout is not on screen", file: file, line: line)
        let banner = app.id("snackbar")
        let bannerUp = banner.exists
        XCTContext.runActivity(named: "Check out at \(checkout.frame); the banner \(bannerUp ? "is up at \(banner.frame)" : "is not up")") { _ in }
        if bannerUp {
            XCTAssertFalse(banner.frame.intersects(checkout.frame), "the banner \(banner.frame) lies over Check out \(checkout.frame)",
                           file: file, line: line)
        }
        XCTAssertTrue(checkout.isHittable, "Check out is not hittable at \(checkout.frame)", file: file, line: line)
    }

    /// The banner sits above the Cart's checkout panel, never over Check out: straight from Add to cart to the Cart,
    /// inside the banner's 10 s, Check out is free and opens the dialog.
    func testTheBannerLeavesCheckOutFree() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        app.id("item_add_to_cart").tapWhenThere()
        XCTAssertTrue(app.id("snackbar").waitForExistence(timeout: 5), "no banner after Add to cart")
        app.back()
        app.openTab("nav_cart")
        XCTAssertTrue(app.id("snackbar").exists, "the banner from Add to cart was gone before the Cart opened: nothing was checked")
        checkOutIsFree()
        app.id("cart_checkout").tapWhenThere()
        expect("dialog_title", shows: "Place this order?")
    }

    /// The budget lands on the step the fraction names, as NthCase's `slide` sets it ($0–200, $10 steps): from $50,
    /// and from wherever the last move left it.
    func testTheBudgetLandsWhereSlideSetsIt() {
        app.signIn()
        app.openLab("lab_form")
        let slider = app.scrollTo(app.id("form_budget"))
        expect("form_budget_value", shows: "$50")
        var wrong: [String] = []
        for (fraction, shown) in [(0.6, "$120"), (0.3, "$60"), (1.0, "$200"), (0.0, "$0"), (0.45, "$90"), (0.6, "$120")] {
            slider.adjust(toNormalizedSliderPosition: CGFloat(fraction))
            let value = app.id("form_budget_value")
            if !value.waitFor(shown, timeout: 2) { wrong.append("\(fraction) shows \(value.label), not \(shown)") }
        }
        XCTAssertEqual(wrong, [], "the budget after each slide")
    }

    /// SPEC.md §4: the edge swipe does what Back does.
    func testTheEdgeSwipeGoesBack() {
        app.signIn()
        app.openLab("lab_slow")
        XCTAssertTrue(app.id("slow_screen").waitForExistence(timeout: 5))
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(app.id("lab_screen").waitForExistence(timeout: 5))
        XCTAssertTrue(app.id("slow_screen").waitToVanish())
    }
}

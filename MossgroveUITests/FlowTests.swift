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

    /// Something on screen shows `text`. A failure lists every look and the screen after them (`mustAppear`).
    private func expect(_ text: String, timeout: TimeInterval = looksTimeout, file: StaticString = #filePath, line: UInt = #line) {
        app.text(text).mustAppear(timeout: timeout, "the screen does not show \"\(text)\"", file: file, line: line)
    }

    /// `id` comes to show `text` (its label or value contains it). One wait, whose looks say "nothing in the tree"
    /// until the element comes: until 1.1 this was two waits of `timeout` each, the second one XCTest's, and its
    /// message read the label again after the wait.
    private func expect(_ id: String, shows text: String, timeout: TimeInterval = looksTimeout, file: StaticString = #filePath, line: UInt = #line) {
        app.id(id).mustContain(text, timeout: timeout, id, file: file, line: line)
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
        last.mustContain("Fruit Bowl", "shop_item_40")
        last.mustContain("No. 040", "shop_item_40")
        app.scrollTo(app.id("shop_item_1"), up: true)
        app.scrollTo(app.id("shop_search"), up: true)
        pullToRefresh(app)
        expect("snackbar_text", shows: "Catalogue is up to date", timeout: 15)
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
        app.id("cart_line_1").mustVanish("line 1 after its Remove")
        expect("cart_total", shows: "$42.00")
        let orderTotal = app.id("cart_total").label
        checkOutIsFree()
        app.id("cart_checkout").tapWhenThere()
        expect("dialog_title", shows: "Place this order?")
        app.id("dialog_dismiss").tapWhenThere()
        app.id("dialog").mustVanish("the dialog after Not now")
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
        // looked for until seen, not once: on the 1.2 round's simulator the first of these looks began 0.03 s after Join's
        // tap and missed "Enter your name", while the three after it saw their lines
        for error in ["Enter your name", "Enter a valid email address", "Enter an age from 18 to 120", "Accept the terms to continue"] {
            app.text(error).mustAppear("the form after Join: \"\(error)\"")
        }
        app.scrollTo(app.id("form_name"), up: true).type("Sam Rivera")
        app.id("form_email").type("sam@example")
        expect("Enter a valid email address")
        app.id("form_email").type(".test")
        app.id("form_email_error").mustVanish("the email error after a valid address")
        app.id("form_age").type("34")
        app.id("form_password").type("garden42x")
        app.id("form_password_toggle").tapWhenThere()
        expect("form_password", shows: "garden42x")
        app.scrollTo(app.id("form_category")).tapWhenThere()
        app.id("form_category_option_garden").tapWhenThere()
        // Moving on from the password to the aisle puts the keyboard away: in the fourth CI run it stayed up, over the
        // newsletter switch, and both taps on the switch landed on it.
        app.keyboards.firstMatch.mustVanish("the keyboard after choosing an aisle")
        app.scrollTo(app.id("form_date")).tapWhenThere()
        let picker = app.id("form_date_picker")
        picker.mustAppear("form_date_picker")
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
        status.mustContain("Tapped", "gestures_status")
        expect("gestures_tap_count", shows: "Taps: 1")
        app.id("gestures_double_tap").doubleTap()
        status.mustContain("Double-tapped", "gestures_status")
        app.id("gestures_long_press").press(forDuration: 1.0)
        status.mustContain("Long-pressed", "gestures_status")
        let swipe = app.id("gestures_swipe")
        swipe.swipeLeft()
        status.mustContain("Swiped left", "gestures_status")
        swipe.swipeRight()
        status.mustContain("Swiped right", "gestures_status")
        swipe.swipeUp()
        status.mustContain("Swiped up", "gestures_status")
        swipe.swipeDown()
        status.mustContain("Swiped down", "gestures_status")
        app.id("gestures_drag_source").press(forDuration: 0.5, thenDragTo: app.id("gestures_drop_target"))
        status.mustContain("Dropped on the drawer", "gestures_status")
        app.scrollTo(app.id("gestures_pinch")).pinch(withScale: 2.0, velocity: 1.0)
        status.mustContain("Pinched out", "gestures_status")
        // not in the scenario (NthCase has no two-finger rotation yet), but the pad works
        app.id("gestures_rotate").rotate(.pi / 2, withVelocity: 1.0)
        status.mustContain("Rotated", "gestures_status")
        app.scrollTo(app.id("gestures_scroll_target")).tapWhenThere()
        status.mustContain("Found the bottom drawer", "gestures_status")
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
        expect("webview_status", shows: "Care guide loaded", timeout: careGuideTimeout)
        let page = app.webViews.firstMatch
        let name = page.textFields.firstMatch
        name.mustAppear("the page's Your name field")
        name.type("Sam")
        choose("Every week", in: page)
        let agree = page.descendants(matching: .any).matching(NSPredicate(format: "label == 'Email me the guide' AND elementType != %d", XCUIElement.ElementType.staticText.rawValue)).firstMatch
        agree.mustAppear("the page's Email me the guide checkbox")
        agree.tap()
        page.buttons["Save"].tap()
        page.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Saved, Sam. We will remind you every week.'")).firstMatch
            .mustAppear("the page's \"Saved, Sam. We will remind you every week.\"")
        page.links["Jump to washing"].tap()
        page.staticTexts["Washing"].mustAppear("the page's Washing")
    }

    // 08 · A slow screen, an error with retry, and empty states
    func test08SlowAndStates() {
        app.signIn()
        app.openLab("lab_slow")
        app.id("slow_slot_1").mustAppear(timeout: slowLoad + looksTimeout, "slow_slot_1")
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
        app.id("shop_item_1").mustAppear(timeout: slowLoad + looksTimeout, "shop_item_1 with Slow loading on")
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
        // Whether iOS will ask: the status says "Not allowed" while iOS does not allow notifications, which on CI's new
        // simulator means it has not asked yet. Looked at, not waited for: a 3 s `waitFor` that ended before its first look
        // answered would take an unasked simulator for an asked one and leave iOS's prompt unanswered (see `waitFor`).
        let notAllowed = "Not allowed. Turn this on to be asked."
        let looks = status.looksUntil(shows: notAllowed, timeout: looksTimeout)
        let askedBefore = !looks.met
        XCTContext.runActivity(named: "Notification status before the switch: " + looks.said
                               + (askedBefore ? "; iOS has been asked before" : "; iOS will ask")) { _ in }
        app.id("settings_theme_dark").tapWhenThere()
        XCTAssertTrue(app.id("settings_theme_dark").isSelected, "Dark is not selected")
        app.id("settings_theme_system").tapWhenThere()
        app.id("settings_notifications").tapWhenThere()
        if !askedBefore { allowNotificationsIfAsked() }
        // 15 s: the status changes when iOS answers the app's request, after the Allow tap; how long that takes on CI
        // has not been measured, so 5 s for it and `looksTimeout` for the looks
        status.mustContain("On: we'll tell you when an order is placed.", timeout: 15,
                           "settings_notifications_status (a refusal from an earlier run on this simulator stops the prompt)")
        app.id("settings_send_notification").tapWhenThere()
        expect("snackbar_text", shows: "Notification sent")
        app.scrollTo(app.id("settings_reset")).tapWhenThere()
        expect("Empty the cart and orders?")
        let cancel = app.id("settings_reset_cancel")
        (cancel.appears(timeout: 3).met ? cancel : app.alerts.buttons["Cancel"].firstMatch).tapWhenThere()
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
        control.mustAppear("the page's Remind me list", file: file, line: line)
        control.tap()
        // the menu iOS opens: its rows are menu items, buttons or cells (a wheel, on an older iOS, has a Done button)
        let candidates = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", option))
        _ = candidates.firstMatch.appears(timeout: looksTimeout)
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
        app.id("signin_screen").mustAppear(timeout: 15, "a cold start shows sign-in first: signin_screen")
        app.signIn(expectShop: false)
        expect("item_name", shows: "Wall Clock")
        expect("item_number", shows: "No. 007")
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
    }

    // 11 · The same link while the app runs and is signed in, from another tab; then an unknown id
    func test11DeepLinkWhileRunning() {
        app.signIn()
        app.openTab("nav_settings")
        app.id("settings_screen").mustAppear("settings_screen")
        app.openLinkWhileRunning("nthcase-sample://item/7")
        // a relaunch would show sign-in: this line names it
        let signIn = app.id("signin_screen").appears(timeout: 2)
        XCTAssertFalse(signIn.met, "the link restarted the app: sign-in is on screen; " + signIn.said)
        expect("item_name", shows: "Wall Clock")
        expect("item_number", shows: "No. 007")
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
        app.openLinkWhileRunning("nthcase-sample://item/999")
        XCTAssertFalse(app.id("signin_screen").exists, "the link restarted the app: sign-in is on screen")
        expect("No drawer has the number")
    }

    // 11 · Signed out and running: sign-in first, then the item
    func test11DeepLinkSignedOutWhileRunning() {
        app.id("signin_screen").mustAppear(timeout: 15, "signin_screen")
        app.openLinkWhileRunning("nthcase-sample://item/7")
        app.id("signin_screen").mustAppear("signed out, the link shows sign-in first: signin_screen")
        app.signIn(expectShop: false)
        expect("item_name", shows: "Wall Clock")
        app.back()
        expect("shop_item_1", shows: "Stoneware Mug")
    }

    /// SPEC.md §4: a tab always opens at its first screen. The bar is not on the screens below a tab, so a tab is
    /// left from below by the app's own ways to another tab (View cart, Start shopping), then chosen again.
    func testATabOpensAtItsFirstScreen() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        app.id("item_screen").mustAppear("item_screen")
        XCTAssertFalse(app.id("nav_shop").exists, "the tab bar is on the item page")
        app.id("item_add_to_cart").tapWhenThere()
        app.id("snackbar_action").tapWhenThere()
        app.id("cart_screen").mustAppear("cart_screen after View cart")
        app.openTab("nav_shop")
        app.id("shop_screen").mustAppear("shop_screen")
        XCTAssertFalse(app.id("item_screen").exists, "Shop came back on the item")
        app.openLab("lab_orders")
        app.id("orders_empty_action").mustAppear("orders_empty_action")
        app.id("orders_empty_action").tapWhenThere()
        app.id("shop_screen").mustAppear("shop_screen after Start shopping")
        app.openTab("nav_lab")
        app.id("lab_screen").mustAppear("lab_screen")
        XCTAssertFalse(app.id("orders_screen").exists, "Lab came back on Orders")
        app.openTab("nav_lab")
        XCTAssertTrue(app.id("lab_screen").exists, "choosing Lab again left its first screen")
    }

    /// Check out is the element a tap reaches: if the banner is up, it is not over Check out. The third CI run's flow
    /// 03 tapped Check out with the Add-to-cart banner still up, and no dialog came.
    private func checkOutIsFree(file: StaticString = #filePath, line: UInt = #line) {
        let checkout = app.id("cart_checkout")
        checkout.mustAppear("cart_checkout", file: file, line: line)
        let banner = app.id("snackbar")
        let bannerUp = banner.exists
        XCTContext.runActivity(named: "Check out at \(checkout.frame); the banner \(bannerUp ? "is up at \(banner.frame)" : "is not up")") { _ in }
        if bannerUp {
            XCTAssertFalse(banner.frame.intersects(checkout.frame), "the banner \(banner.frame) lies over Check out \(checkout.frame)",
                           file: file, line: line)
        }
        XCTAssertTrue(checkout.isHittable, "Check out is not hittable at \(checkout.frame)", file: file, line: line)
    }

    /// The banner sits above the Cart's checkout panel, never over Check out: with a banner up on the Cart, Check out
    /// is free and opens the dialog.
    ///
    /// The banner is the Shop's, from a refresh, and the Cart is then one tap away on the bar. Until now the test took
    /// the Add-to-cart banner to the Cart by Back and the tab, and in CI run 44388145174 it read the Cart 23 s after
    /// Add to cart, long after the banner's 10 s: Back's 1.5 s look for iOS's "Save Password?" card took 9.7 s on that
    /// runner, and the tab 6.5 s. The two runs before had passed with 0.8 s and 1.9 s to spare. The app has no way to
    /// bring a banner onto a full Cart without that walk: View cart closes the banner as it opens the Cart, and the
    /// Cart's own banner (Order placed) comes with an empty cart and no Check out.
    ///
    /// So the time is measured, not hoped for: a try counts when the Cart shows the banner within 6 s of its being seen,
    /// which leaves checkOutIsFree about 4 s for its own looks, and a slower try is made again, three times at most.
    func testTheBannerLeavesCheckOutFree() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        app.id("item_add_to_cart").tapWhenThere()
        app.back()
        var tries: [String] = []
        var bannerOnTheCart = false
        for attempt in 1...3 where !bannerOnTheCart {
            if attempt > 1 { app.openTab("nav_shop") }
            app.id("shop_list").mustAppear("the shop's list")
            app.answerSavePasswordCard()
            pullToRefresh(app)
            let banner = app.id("snackbar_text").waitFor("Catalogue is up to date", timeout: 8)
            guard banner.met else {
                tries.append("try \(attempt): no banner after the refresh: snackbar_text never showed \"Catalogue is up to date\" " + banner.said)
                continue
            }
            let seen = Date()
            // the bare tap: no look for the card, no wait for hittable, so nothing but the tab change runs the clock
            app.tab("nav_cart").tap()
            let onTheCart = app.id("cart_screen").appears(timeout: 5).met
            let up = app.id("snackbar").exists
            let after = Date().timeIntervalSince(seen)
            tries.append("try \(attempt): " + (onTheCart ? "the Cart" : "no cart_screen")
                         + String(format: " %.1f s after the banner was seen, ", after) + (up ? "banner up" : "banner gone"))
            bannerOnTheCart = onTheCart && up && after < 6
        }
        XCTContext.runActivity(named: "The banner on the Cart: " + tries.joined(separator: "; ")) { _ in }
        XCTAssertTrue(bannerOnTheCart, "no try had the banner on the Cart within 6 s, so nothing was checked: "
                      + tries.joined(separator: "; "))
        checkOutIsFree()
        app.id("cart_checkout").tapWhenThere()
        expect("dialog_title", shows: "Place this order?")
    }

    /// The budget lands on the step the fraction names, as NthCase's `slide` sets it ($0–200, $10 steps): from $50,
    /// and from wherever the last move left it.
    ///
    /// Each slide is given 10 s to show its step, and a slide that does not lists what every look saw and when. Until
    /// 1.1 this test gave each slide 2 s, where the flows' other checks of what a screen shows wait 5 s, and then read
    /// the label once more for its message. In CI run 44323850081 the simulator answered each look in 1.2 s and some in 6 to 20 s, for this test
    /// alone and from its sign-in on: 2 s held one or two looks, and the later read showed the right step, so the run
    /// said "0.3 shows $60, not $60". Same Xcode (26.6, 17F113), same iOS 26.5, and no change to the form, the slider
    /// or this test since v1.0.0, where it passed in 33 s.
    func testTheBudgetLandsWhereSlideSetsIt() {
        app.signIn()
        app.openLab("lab_form")
        let slider = app.scrollTo(app.id("form_budget"))
        expect("form_budget_value", shows: "$50")
        var wrong: [String] = []
        for (fraction, shown) in [(0.6, "$120"), (0.3, "$60"), (1.0, "$200"), (0.0, "$0"), (0.45, "$90"), (0.6, "$120")] {
            slider.adjust(toNormalizedSliderPosition: CGFloat(fraction))
            let looks = app.id("form_budget_value").looksUntil(shows: shown, timeout: 10)
            if !looks.met {
                wrong.append("\(fraction) never showed \(shown) " + looks.said)
            }
        }
        XCTAssertEqual(wrong, [], "the budget after each slide")
    }

    /// SPEC.md §4: the edge swipe does what Back does.
    func testTheEdgeSwipeGoesBack() {
        app.signIn()
        app.openLab("lab_slow")
        app.id("slow_screen").mustAppear("slow_screen")
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        app.id("lab_screen").mustAppear("lab_screen after the edge swipe")
        app.id("slow_screen").mustVanish("slow_screen after the edge swipe")
    }

    /// SPEC.md §5, the Feed (1.2): 20 rows at first; when the third row from the end shows, a spinner row after the last
    /// row, which goes 1 s later, and 20 more rows in its place; and so on: three loads here, to row 61, and no end.
    ///
    /// Each load is brought by drags that stop a row short of the row that starts it, then one quick stroke to the
    /// list's end (`bringFeedSpinner`), so the spinner row is in sight during its second and the look for it begins as
    /// the stroke ends. The rows must come every time, and only after the list reached its end. The spinner row must be
    /// seen in one load of the three: on the local simulator XCUITest took up to 1.8 s for one look, longer than the
    /// spinner's second, so one look may come late, but three in a row only when the spinner never shows (seen in 3 of 3
    /// on 2026-11-23). FeedViewTests proves the spinner's second inside the app, where the clock is the app's own.
    func testTheFeedNeverEnds() {
        app.signIn()
        app.openLab("lab_feed")
        app.id("feed_list").mustAppear("the Feed: feed_list")
        app.id("feed_row_1").mustShow("Feed row 1", "the Feed's first row")
        XCTAssertFalse(app.id("feed_loading").exists, "a spinner row before any scroll")
        var seen = 0
        for count in [20, 40, 60] {
            XCTAssertFalse(app.id("feed_row_\(count + 1)").exists, "row \(count + 1) before the list reached row \(count - 2)")
            let placed = app.bringFeedSpinner(count: count)
            let spinner = app.id("feed_loading").appears(timeout: feedSpinnerLook)
            let gone = spinner.met ? app.id("feed_loading").vanishes(timeout: looksTimeout) : nil
            let next = app.id("feed_row_\(count + 1)")
            next.mustShow("Feed row \(count + 1)", timeout: looksTimeout, "the 20 rows after row \(count)")
            if spinner.met { seen += 1 }
            let line = "load at \(count) rows: " + (placed ? "brought to the end by one quick stroke" : "the drags started it")
                + "; spinner " + (spinner.met ? String(format: "seen %.1f s after the stroke", spinner.looks.last?.after ?? 0) : "not seen \(spinner.said)")
                + (gone.map { $0.met ? String(format: ", gone %.1f s later", $0.looks.last?.after ?? 0) : ", still there \($0.said)" } ?? "")
            print("FEED: \(line)")
            XCTContext.runActivity(named: "FEED: \(line)") { _ in }
            if let gone, !gone.met { XCTFail("the spinner row after row \(count) never went \(gone.said)") }
        }
        let found = "FEED: the spinner row seen in \(seen) of 3 loads"
        print(found)
        XCTContext.runActivity(named: found) { _ in }
        XCTAssertGreaterThan(seen, 0, "the spinner row (feed_loading) was never seen in three loads")
        XCTAssertFalse(app.text("End of the feed").exists, "the Feed has an end")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "the Feed after three loads"
        shot.lifetime = .keepAlways
        add(shot)
    }
}

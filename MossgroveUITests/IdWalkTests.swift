import XCTest

/// The id walk: every screen, in the state the spec names, and every native id of `test-ids.json` on it, read from
/// XCUITest's tree, which is the tree Appium's XCUITest driver reads (an id is an element's `name` there).
///
/// The `web_*` ids are HTML ids inside the care guide's page: Appium sees them only in the page's WEBVIEW context,
/// never in this tree, so the walk checks the page's native frame (`webview`) and leaves them to SourceCensusTests.
final class IdWalkTests: XCTestCase {
    struct Step {
        let name: String
        let ids: [String]
        let act: (XCUIApplication) -> Void
    }

    // MARK: The walk, as data, so testTheWalkCoversEveryId can read it

    static let signedOut: [Step] = [
        Step(name: "Sign in", ids: ["signin_screen", "signin_email", "signin_password", "signin_password_toggle", "signin_submit",
                                    "signin_test_account", "signin_use_test_account"]) { _ in },
        Step(name: "Sign in, refused", ids: ["signin_error"]) { app in
            app.id("signin_email").type("tester@mossgrove.test")
            app.id("signin_password").type("letmein1")
            app.id("signin_submit").tap()
        },
        Step(name: "Deep link, unknown id", ids: ["item_screen", "item_not_found", "item_not_found_action", "top_bar_title", "top_bar_back"]) { app in
            app.open(URL(string: "nthcase-sample://item/999")!)
            app.signIn(expectShop: false)
        },
    ]

    static let shopAndCart: [Step] = [
        Step(name: "Shop", ids: ["nav_shop", "nav_cart", "nav_lab", "nav_settings", "shop_screen", "shop_search", "shop_count",
                                 "shop_list", "shop_item_1"]) { app in app.signIn() },
        Step(name: "Shop, the last row", ids: ["shop_item_40"]) { app in
            app.scrollTo(app.id("shop_item_40"))
        },
        Step(name: "Shop, searching", ids: ["shop_search_clear", "shop_item_5"]) { app in
            app.scrollTo(app.id("shop_search"), up: true)
            app.id("shop_search").type("lamp\n")
        },
        Step(name: "Shop, no match", ids: ["shop_empty", "shop_empty_action"]) { app in
            app.id("shop_search").replace(with: "velvet\n")
        },
        Step(name: "Shop, refreshed", ids: ["snackbar", "snackbar_text"]) { app in
            app.id("shop_empty_action").tap()
            pullToRefresh(app)
        },
        Step(name: "Item", ids: ["item_screen", "item_image", "item_number", "item_name", "item_price", "item_description",
                                 "item_qty_decrease", "item_qty_value", "item_qty_increase", "item_add_to_cart", "top_bar_title",
                                 "top_bar_back"]) { app in
            app.id("shop_item_1").tap()
        },
        Step(name: "Item, added", ids: ["snackbar", "snackbar_text", "snackbar_action"]) { app in
            app.id("item_add_to_cart").tap()
        },
        Step(name: "Cart", ids: ["cart_screen", "cart_list", "cart_line_1", "cart_line_decrease_1", "cart_line_qty_1",
                                 "cart_line_increase_1", "cart_line_remove_1", "cart_line_total_1", "cart_total", "cart_checkout",
                                 "top_bar_title"]) { app in
            app.id("snackbar_action").tap()
        },
        Step(name: "Checkout dialog", ids: ["dialog", "dialog_title", "dialog_text", "dialog_confirm", "dialog_dismiss"]) { app in
            app.id("cart_checkout").tap()
        },
        Step(name: "Cart, empty", ids: ["cart_empty", "cart_empty_action", "snackbar_action"]) { app in
            app.id("dialog_confirm").tap()
        },
        Step(name: "Orders, one order", ids: ["orders_screen", "orders_list", "orders_row_1", "top_bar_back"]) { app in
            app.id("snackbar_action").tap()
        },
    ]

    static let labBenches: [Step] = [
        Step(name: "Lab", ids: ["lab_screen", "lab_form", "lab_gestures", "lab_webview", "lab_slow", "lab_orders", "lab_gift_cards",
                                "top_bar_title"]) { app in
            app.signIn()
            app.openTab(2, "nav_lab")
        },
        Step(name: "Join the club", ids: ["form_screen", "form_name", "form_email", "form_age", "form_password", "form_password_toggle",
                                          "form_category", "form_date", "form_newsletter", "form_budget", "form_budget_value",
                                          "form_terms", "form_submit"]) { app in
            app.id("lab_form").tap()
        },
        Step(name: "Join the club, refused", ids: ["form_name_error", "form_email_error", "form_age_error", "form_password_error",
                                                   "form_category_error", "form_date_error", "form_terms_error"]) { app in
            app.scrollTo(app.id("form_submit")).tap()
        },
        Step(name: "Join the club, dropdown open", ids: ["form_category_option_kitchen", "form_category_option_desk",
                                                         "form_category_option_garden", "form_category_option_home"]) { app in
            app.scrollTo(app.id("form_category"), up: true).tap()
        },
        Step(name: "Join the club, date picker", ids: ["form_date_picker", "form_date_confirm", "form_date_cancel"]) { app in
            app.id("form_category_option_garden").tap()
            app.scrollTo(app.id("form_date")).tap()
        },
        Step(name: "Join the club, joined", ids: ["form_result"]) { app in
            app.id("form_date_confirm").tap()
            app.scrollTo(app.id("form_name"), up: true)
            app.id("form_name").type("Sam Rivera\n")
            app.id("form_email").type("sam@example.test\n")
            app.id("form_age").type("34")
            app.id("form_password").type("garden42x\n")
            app.scrollTo(app.id("form_terms")).tap()
            app.scrollTo(app.id("form_submit")).tap()
            app.scrollTo(app.id("form_result"))
        },
        Step(name: "Gestures", ids: ["gestures_screen", "gestures_status", "gestures_orientation", "gestures_tap", "gestures_tap_count",
                                     "gestures_double_tap", "gestures_long_press", "gestures_swipe", "gestures_drag_source",
                                     "gestures_drop_target", "gestures_pinch", "gestures_zoom_value", "gestures_rotate",
                                     "gestures_rotation_value", "gestures_scroll"]) { app in
            app.back()
            app.id("lab_gestures").tap()
        },
        Step(name: "Gestures, the bottom drawer", ids: ["gestures_scroll_target"]) { app in
            app.scrollTo(app.id("gestures_scroll_target"))
        },
        Step(name: "Care guide", ids: ["webview_screen", "webview", "webview_status"]) { app in
            app.back()
            app.id("lab_webview").tap()
        },
        Step(name: "Delivery slots, loading", ids: ["slow_screen", "slow_loading"]) { app in
            app.back()
            app.id("lab_slow").tap()
        },
        Step(name: "Delivery slots", ids: ["slow_content", "slow_slot_1", "slow_slot_2", "slow_slot_3", "slow_slot_4", "slow_slot_5",
                                           "slow_reload"]) { app in
            _ = app.id("slow_content").waitForExistence(timeout: 8)
        },
        Step(name: "Orders, none", ids: ["orders_screen", "orders_empty", "orders_empty_action"]) { app in
            app.back()
            app.id("lab_orders").tap()
        },
    ]

    static let settingsAndStates: [Step] = [
        Step(name: "Settings", ids: ["settings_screen", "settings_account_email", "settings_orders", "settings_sign_out",
                                     "settings_theme", "settings_theme_system", "settings_theme_light", "settings_theme_dark",
                                     "settings_notifications", "settings_notifications_status", "top_bar_title"]) { app in
            app.signIn()
            app.openTab(3, "nav_settings")
        },
        Step(name: "Settings, lower down", ids: ["settings_send_notification", "settings_slow_loading", "settings_fail_loading",
                                                 "settings_reset", "settings_version"]) { app in
            app.scrollTo(app.id("settings_version"))
        },
        Step(name: "Settings, reset dialog", ids: ["settings_reset_cancel", "settings_reset_confirm"]) { app in
            app.id("settings_reset").tap()
        },
        Step(name: "Shop, failed", ids: ["shop_error", "shop_retry"]) { app in
            app.id("settings_reset_cancel").tap()
            app.scrollTo(app.id("settings_fail_loading")).set(true)
            app.openTab(0, "nav_shop")
        },
        Step(name: "Orders, failed", ids: ["orders_error", "orders_retry"]) { app in
            app.openLab("lab_orders")
        },
        Step(name: "Shop, slow", ids: ["shop_loading"]) { app in
            app.openTab(3, "nav_settings")
            app.scrollTo(app.id("settings_fail_loading")).set(false)
            app.id("settings_slow_loading").set(true)
            app.openTab(0, "nav_shop")
        },
        Step(name: "Orders, slow", ids: ["orders_loading"]) { app in
            app.openLab("lab_orders")
        },
    ]

    // MARK: Tests

    func testSignedOut() { walk(Self.signedOut) }
    func testShopAndCart() { walk(Self.shopAndCart) }
    func testLabBenches() { walk(Self.labBenches) }
    func testSettingsAndStates() { walk(Self.settingsAndStates) }

    /// Gift cards has no ids at all: no id of the list is in the tree while it is shown.
    func testGiftCardsHasNoIds() {
        let app = XCUIApplication()
        app.launch()
        app.signIn()
        app.openLab("lab_gift_cards")
        XCTAssertTrue(app.text("Check a balance").waitForExistence(timeout: 5))
        let ids = app.identifiers()
        let spec = ids.filter { id in SpecIds.shared.ids.contains { SpecIds.matches(id, $0.id) } }
        XCTAssertEqual(spec, [], "Gift cards shows ids of the list")
        // Anything else is the system's own naming, not the app's: recorded, so the run shows what Appium would see.
        XCTContext.runActivity(named: "Every identifier in the tree on Gift cards: \(ids)") { _ in }
    }

    /// The walk names every native id of the list at least once (templates by one instance or more).
    func testTheWalkCoversEveryId() {
        let walked = (Self.signedOut + Self.shopAndCart + Self.labBenches + Self.settingsAndStates).flatMap(\.ids)
        let missing = SpecIds.shared.native.map(\.id).filter { entry in !walked.contains { SpecIds.matches($0, entry) } }
        XCTAssertEqual(missing, [], "ids the walk never checks")
        let unknown = walked.filter { id in !SpecIds.shared.native.contains { SpecIds.matches(id, $0.id) } }
        XCTAssertEqual(unknown, [], "ids the walk checks that are not in the list")
    }

    // MARK: Walking

    /// Walks every step, whatever an earlier one found, and checks every id of every step. The walk fails once, at
    /// its end, with every missing id and every id outside the list, screen by screen; each step's own activity
    /// carries its screenshot and what it found.
    private func walk(_ steps: [Step]) {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launch()
        var problems: [String] = []
        for step in steps {
            XCTContext.runActivity(named: step.name) { activity in
                step.act(app)
                let missing = step.ids.filter { !app.id($0).waitForExistence(timeout: 8) }
                let tree = app.identifiers()
                // An id-shaped name that is not in the list would be an id outside the spec.
                let outside = tree.filter { id in
                    looksLikeASpecId(id) && !SpecIds.shared.ids.contains { SpecIds.matches(id, $0.id) }
                }
                let repeated = step.ids.filter { id in tree.filter { $0 == id }.count > 1 }
                if !missing.isEmpty { problems.append("\(step.name): not in the tree: \(missing.joined(separator: " "))") }
                if !outside.isEmpty { problems.append("\(step.name): outside the list: \(outside.joined(separator: " "))") }
                let found = "\(step.ids.count - missing.count) of \(step.ids.count) ids"
                    + (missing.isEmpty ? "" : "; missing \(missing.joined(separator: " "))")
                    + (outside.isEmpty ? "" : "; outside the list \(outside.joined(separator: " "))")
                    + (repeated.isEmpty ? "" : "; more than one element named \(repeated.joined(separator: " "))")
                XCTContext.runActivity(named: found) { _ in }
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = step.name
                shot.lifetime = missing.isEmpty && outside.isEmpty ? .deleteOnSuccess : .keepAlways
                activity.add(shot)
            }
        }
        if !problems.isEmpty {
            XCTFail("\(problems.count) screen problem(s) on this walk:\n" + problems.joined(separator: "\n"))
        }
    }

    private func looksLikeASpecId(_ id: String) -> Bool {
        let prefixes = Set(SpecIds.shared.ids.map { String($0.id.prefix { $0 != "_" }) })
        guard let head = id.split(separator: "_").first, id.contains("_") else { return prefixes.contains(id) }
        return prefixes.contains(String(head))
    }
}

/// Pulls the shop's list down far enough to refresh it.
func pullToRefresh(_ app: XCUIApplication) {
    let list = app.id("shop_list")
    let top = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
    top.press(forDuration: 0.1, thenDragTo: list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
}

extension XCUIApplication {
    /// Sign in with the test account; `expectShop: false` when a deep link opens something else.
    func signIn(expectShop: Bool) {
        if expectShop { signIn(); return }
        XCTAssertTrue(id("signin_email").waitForExistence(timeout: 15))
        id("signin_use_test_account").tap()
        id("signin_submit").tap()
    }
}

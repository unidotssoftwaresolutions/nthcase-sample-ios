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
        /// A banner the step brings up, looked for right after `act` (see `Banner`).
        var banner: Banner? = nil
        /// A spinner the step brings up for about a second, looked for right after `act` (see `Spinner`).
        var spinner: Spinner? = nil
        let act: (XCUIApplication) -> Void
    }

    /// New in 1.2: the Feed's spinner row shows for 1 s, and only while the list is at its end, so the walk's own read of
    /// the tree, after its look for the "Save Password?" card, would come too late for it. The step's action brings it
    /// into sight (`bringFeedSpinner`), and the walk looks for its ids at once, one look after another, for
    /// `feedSpinnerLook`; missed, `again` brings the next load's spinner, up to `attempts` in all. Those ids are checked by
    /// that look alone: seen there, they were in the tree, the same tree the walk reads.
    ///
    /// Never seen is said, with every look, and kept with the step's screenshot and tree, but fails nothing: on the local
    /// simulator XCUITest took 2.5 to 3.5 s to make one stroke and up to 1.8 s for one look, so on a slower runner a look
    /// can come after the second has gone whatever the app does. FlowTests' testTheFeedNeverEnds requires the spinner row,
    /// by this id, in one load of three; FeedViewTests proves its second inside the app; SourceCensusTests that its id is
    /// on it. (Seen at the first try on 2026-11-23.)
    struct Spinner {
        let ids: [String]
        var attempts = 1
        var again: ((XCUIApplication, Int) -> Void)? = nil
    }

    /// A banner lasts 10 s (`AppModel.snackSeconds`), and the walk reads a screen only after its look for iOS's "Save
    /// Password?" card and its one read of the whole tree, each of which has taken several seconds on GitHub's runners.
    /// Release run 44511785935 found neither `snackbar` nor `snackbar_text` on "Shop, refreshed", where the same commit's
    /// build run an hour earlier had found both. So the banner is looked for at once, right after the step's action:
    /// one look after another (`Looks.until`, for `looksTimeout`) until `snackbar_text` shows `text` with `snackbar`
    /// in the tree around it. That showing is the step's check: the text comes only when the action's work is done (for
    /// the refresh, once ShopView's refresh() has finished), and it is read from the element with that id, so a banner
    /// the app no longer shows, or shows without either id, is never seen and fails the walk as before. Seen, the two
    /// ids count as in the tree; if the walk's later read no longer finds them, the walk says the banner had gone by
    /// then, and fails nothing for it.
    struct Banner {
        let text: String
        static let ids = ["snackbar", "snackbar_text"]
    }

    // MARK: The walk, as data, so testTheWalkCoversEveryId can read it

    static let signedOut: [Step] = [
        Step(name: "Sign in", ids: ["signin_screen", "signin_email", "signin_password", "signin_password_toggle", "signin_submit",
                                    "signin_test_account", "signin_use_test_account"]) { _ in },
        Step(name: "Sign in, refused", ids: ["signin_error"]) { app in
            app.id("signin_email").type("tester@mossgrove.test")
            app.id("signin_password").type("letmein1")
            app.id("signin_submit").tapWhenThere()
        },
        Step(name: "Deep link, unknown id", ids: ["item_screen", "item_not_found", "item_not_found_action", "top_bar_title", "top_bar_back"]) { app in
            app.openLinkFromColdStart("nthcase-sample://item/999")
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
        Step(name: "Shop, refreshed", ids: ["snackbar", "snackbar_text"], banner: Banner(text: "Catalogue is up to date")) { app in
            app.id("shop_empty_action").tapWhenThere()
            pullToRefresh(app)
        },
        Step(name: "Item", ids: ["item_screen", "item_image", "item_number", "item_name", "item_price", "item_description",
                                 "item_qty_decrease", "item_qty_value", "item_qty_increase", "item_add_to_cart", "top_bar_title",
                                 "top_bar_back"]) { app in
            app.id("shop_item_1").tapWhenThere()
        },
        Step(name: "Item, added", ids: ["snackbar", "snackbar_text", "snackbar_action"]) { app in
            app.id("item_add_to_cart").tapWhenThere()
        },
        Step(name: "Cart", ids: ["cart_screen", "cart_list", "cart_line_1", "cart_line_decrease_1", "cart_line_qty_1",
                                 "cart_line_increase_1", "cart_line_remove_1", "cart_line_total_1", "cart_total", "cart_checkout",
                                 "top_bar_title"]) { app in
            app.id("snackbar_action").tapWhenThere()
        },
        Step(name: "Checkout dialog", ids: ["dialog", "dialog_title", "dialog_text", "dialog_confirm", "dialog_dismiss"]) { app in
            app.id("cart_checkout").tapWhenThere()
        },
        Step(name: "Cart, empty", ids: ["cart_empty", "cart_empty_action", "snackbar_action"]) { app in
            app.id("dialog_confirm").tapWhenThere()
        },
        Step(name: "Orders, one order", ids: ["orders_screen", "orders_list", "orders_row_1", "top_bar_back"]) { app in
            app.id("snackbar_action").tapWhenThere()
        },
    ]

    static let labBenches: [Step] = [
        Step(name: "Lab", ids: ["lab_screen", "lab_form", "lab_gestures", "lab_webview", "lab_slow", "lab_orders", "lab_gift_cards",
                                "lab_feed", "top_bar_title"]) { app in
            app.signIn()
            app.openTab("nav_lab")
        },
        Step(name: "Join the club", ids: ["form_screen", "form_name", "form_email", "form_age", "form_password", "form_password_toggle",
                                          "form_category", "form_date", "form_newsletter", "form_budget", "form_budget_value",
                                          "form_terms", "form_submit"]) { app in
            app.id("lab_form").tapWhenThere()
        },
        Step(name: "Join the club, refused", ids: ["form_name_error", "form_email_error", "form_age_error", "form_password_error",
                                                   "form_category_error", "form_date_error", "form_terms_error"]) { app in
            app.scrollTo(app.id("form_submit")).tapWhenThere()
        },
        Step(name: "Join the club, dropdown open", ids: ["form_category_option_kitchen", "form_category_option_desk",
                                                         "form_category_option_garden", "form_category_option_home"]) { app in
            app.scrollTo(app.id("form_category"), up: true).tapWhenThere()
        },
        Step(name: "Join the club, date picker", ids: ["form_date_picker", "form_date_confirm", "form_date_cancel"]) { app in
            app.id("form_category_option_garden").tapWhenThere()
            app.scrollTo(app.id("form_date")).tapWhenThere()
        },
        Step(name: "Join the club, joined", ids: ["form_result"]) { app in
            app.id("form_date_confirm").tapWhenThere()
            app.scrollTo(app.id("form_name"), up: true)
            app.id("form_name").type("Sam Rivera\n")
            app.id("form_email").type("sam@example.test\n")
            app.id("form_age").type("34")
            app.id("form_password").type("garden42x\n")
            app.scrollTo(app.id("form_terms")).tapWhenThere()
            app.scrollTo(app.id("form_submit")).tapWhenThere()
            app.scrollTo(app.id("form_result"))
        },
        Step(name: "Gestures", ids: ["gestures_screen", "gestures_status", "gestures_orientation", "gestures_tap", "gestures_tap_count",
                                     "gestures_double_tap", "gestures_long_press", "gestures_swipe", "gestures_drag_source",
                                     "gestures_drop_target", "gestures_pinch", "gestures_zoom_value", "gestures_rotate",
                                     "gestures_rotation_value", "gestures_scroll"]) { app in
            app.back()
            app.id("lab_gestures").tapWhenThere()
        },
        Step(name: "Gestures, the bottom drawer", ids: ["gestures_scroll_target"]) { app in
            app.scrollTo(app.id("gestures_scroll_target"))
        },
        Step(name: "Care guide", ids: ["webview_screen", "webview", "webview_status"]) { app in
            app.back()
            app.id("lab_webview").tapWhenThere()
        },
        Step(name: "Delivery slots, loading", ids: ["slow_screen", "slow_loading"]) { app in
            app.back()
            app.id("lab_slow").tapWhenThere()
        },
        Step(name: "Delivery slots", ids: ["slow_content", "slow_slot_1", "slow_slot_2", "slow_slot_3", "slow_slot_4", "slow_slot_5",
                                           "slow_reload"]) { app in
            _ = app.id("slow_content").appears(timeout: slowLoad + looksTimeout)
        },
        Step(name: "Orders, none", ids: ["orders_screen", "orders_empty", "orders_empty_action"]) { app in
            app.back()
            app.id("lab_orders").tapWhenThere()
        },
        // The Feed (1.2): its first rows, then its spinner row, which lasts 1 s at the list's end (see Spinner), then the
        // 20 rows that come in its place.
        Step(name: "Feed", ids: ["feed_screen", "feed_list", "feed_row_1", "top_bar_title", "top_bar_back"]) { app in
            app.back()
            app.id("lab_feed").tapWhenThere()
        },
        Step(name: "Feed, loading", ids: ["feed_list"],
             spinner: Spinner(ids: ["feed_loading"], attempts: 3, again: { app, tries in app.bringFeedSpinner(count: 20 + 20 * tries) })) { app in
            app.bringFeedSpinner(count: 20)
        },
        // the rows the first load brought, back up the list from wherever the loads left it
        Step(name: "Feed, 20 more", ids: ["feed_row_21"]) { app in
            _ = app.id("feed_loading").vanishes(timeout: looksTimeout)
            app.scrollInside(app.id("feed_list"), until: app.id("feed_row_21"), up: true)
        },
    ]

    static let settingsAndStates: [Step] = [
        Step(name: "Settings", ids: ["settings_screen", "settings_account_email", "settings_orders", "settings_sign_out",
                                     "settings_theme", "settings_theme_system", "settings_theme_light", "settings_theme_dark",
                                     "settings_notifications", "settings_notifications_status", "top_bar_title"]) { app in
            app.signIn()
            app.openTab("nav_settings")
        },
        Step(name: "Settings, lower down", ids: ["settings_send_notification", "settings_slow_loading", "settings_fail_loading",
                                                 "settings_reset", "settings_version"]) { app in
            app.scrollTo(app.id("settings_version"))
        },
        Step(name: "Settings, reset dialog", ids: ["settings_reset_cancel", "settings_reset_confirm"]) { app in
            app.id("settings_reset").tapWhenThere()
        },
        Step(name: "Shop, failed", ids: ["shop_error", "shop_retry"]) { app in
            app.id("settings_reset_cancel").tapWhenThere()
            app.scrollTo(app.id("settings_fail_loading")).set(true)
            app.openTab("nav_shop")
        },
        Step(name: "Orders, failed", ids: ["orders_error", "orders_retry"]) { app in
            app.openLab("lab_orders")
        },
        Step(name: "Shop, slow", ids: ["shop_loading"]) { app in
            app.back()
            app.openTab("nav_settings")
            app.scrollTo(app.id("settings_fail_loading")).set(false)
            app.id("settings_slow_loading").set(true)
            app.openTab("nav_shop")
        },
        Step(name: "Orders, slow", ids: ["orders_loading"]) { app in
            app.openLab("lab_orders")
        },
    ]

    /// The Lobby (1.1), built twice: `lab_lobby` (SwiftUI) and `lab_lobby_views` (UIKit) carry the same ids. Every
    /// tap here is on an element of the Lobby's own, and the page is scrolled by a drag in its left margin, outside
    /// every row, so the walk itself touches nothing by accident.
    static func lobby(_ bench: String) -> [Step] {
        [
            // The Lab is a tab's first screen: it has no Back (1.0's "Lab" step does not ask for one either). Back is
            // the Lobby's, checked on the next step (CI run 44323850081 looked for it here).
            Step(name: "Lobby (\(bench))", ids: ["lab_lobby", "lab_lobby_views", "top_bar_title"]) { app in
                app.signIn()
                app.openTab("nav_lab")
            },
            Step(name: "Lobby (\(bench)), open", ids: ["lobby_screen", "lobby_touch_log", "lobby_touch_count", "lobby_touch_reset",
                                                       "lobby_saved_delay", "lobby_saved_delay_0", "lobby_saved_delay_3",
                                                       "lobby_saved_delay_6", "lobby_saved_delay_12", "lobby_saved_delay_20",
                                                       "lobby_pager_shown", "lobby_pager", "lobby_banner_1", "lobby_pager_position",
                                                       "lobby_pager_auto", "lobby_top_row_position", "lobby_top_row",
                                                       "lobby_top_row_tile_1", "lobby_page", "lobby_chips", "lobby_chip_1",
                                                       "lobby_row_1_position", "lobby_row_1", "lobby_row_1_tile_1", "lobby_bar",
                                                       "lobby_bar_home", "lobby_bar_live", "lobby_bar_saved", "lobby_bar_offers",
                                                       "top_bar_title", "top_bar_back"]) { app in
                app.id(bench).tapWhenThere()
            },
            Step(name: "Lobby (\(bench)), a tile's detail", ids: ["lobby_detail", "lobby_detail_back"]) { app in
                app.id("lobby_top_row_tile_1").tapWhenThere()
            },
            Step(name: "Lobby (\(bench)), a banner's promo", ids: ["lobby_promo", "lobby_promo_back"]) { app in
                app.id("lobby_detail_back").tapWhenThere()
                app.id("lobby_banner_1").tapWhenThere()
            },
            Step(name: "Lobby (\(bench)), the quick sheet", ids: ["lobby_sheet", "lobby_sheet_title", "lobby_sheet_open",
                                                                  "lobby_sheet_preview", "lobby_sheet_saved", "lobby_sheet_rate",
                                                                  "lobby_sheet_more", "lobby_sheet_more_row_1"]) { app in
                app.id("lobby_promo_back").tapWhenThere()
                app.longPressWhenThere(app.id("lobby_top_row_tile_1"))
            },
            // 1.2: More like this is the sheet's own scroller, and its last line comes only by scrolling inside it
            Step(name: "Lobby (\(bench)), the sheet's last line", ids: ["lobby_sheet_more_row_20"]) { app in
                app.scrollInside(app.id("lobby_sheet_more"), until: app.id("lobby_sheet_more_row_20"))
            },
            Step(name: "Lobby (\(bench)), Saved", ids: ["lobby_saved_screen", "lobby_bar"]) { app in
                app.id("lobby_sheet_rate").tapWhenThere()
                _ = app.id("lobby_sheet").vanishes(timeout: looksTimeout)
                app.id("lobby_bar_saved").tapWhenThere()
            },
            // The grid has a step of its own. The page shows 176 to 393 points of itself, and a cell that scrolls out of
            // it leaves the tree (SwiftUI's LazyVStack, UIKit's collection view), so by the time the board's first cell
            // showed, the grid had gone (CI run 44323850081). The grid is reached by drags that do not fling: a flung
            // drag moved the page about 300 points, more than a grid cell stays in sight.
            Step(name: "Lobby (\(bench)), the grid", ids: ["lobby_grid", "lobby_grid_cell_1"]) { app in
                app.id("lobby_bar_home").tapWhenThere()
                app.scrollLobbyPage(until: app.id("lobby_grid_cell_1"), gently: true)
            },
            // The inner list and the board each have a step of their own too, both reached gently. With the pager on,
            // SwiftUI's page shows 176 points, and the inner list's first row is more than that above the board's
            // first cell, so one look cannot have both on screen. In CI run 44346625956 one step scrolled on from the
            // grid with flung drags: after the third the board's first cell was in the tree but above the page's
            // window, so it was never hittable, and the 22 drags left took the page to its end. The inner list had
            // scrolled out above and left the tree. Run 44323850081 had found both only because its drags happened
            // to stop with the board's first cell low in the window.
            Step(name: "Lobby (\(bench)), the inner list", ids: ["lobby_inner_list", "lobby_inner_row_1"]) { app in
                app.scrollLobbyPage(until: app.id("lobby_inner_row_1"), gently: true)
            },
            Step(name: "Lobby (\(bench)), the board", ids: ["lobby_board_position", "lobby_board", "lobby_board_cell_a1"]) { app in
                app.scrollLobbyPage(until: app.id("lobby_board_cell_a1"), gently: true)
            },
            Step(name: "Lobby (\(bench)), the end", ids: ["lobby_footer"]) { app in
                app.scrollLobbyPage(until: app.id("lobby_footer"))
            },
        ]
    }

    // MARK: Tests

    func testLobby() { walk(Self.lobby("lab_lobby")) }
    func testLobbyUIKit() { walk(Self.lobby("lab_lobby_views")) }
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
        app.text("Check a balance").mustAppear("\"Check a balance\"")
        let ids = app.identifiers()
        let spec = ids.filter { id in SpecIds.shared.ids.contains { SpecIds.matches(id, $0.id) } }
        XCTAssertEqual(spec, [], "Gift cards shows ids of the list")
        // Anything else is the system's own naming, not the app's: recorded, so the run shows what Appium would see.
        XCTContext.runActivity(named: "Every identifier in the tree on Gift cards: \(ids)") { _ in }
    }

    /// Each `nav_*` id is on the element a person taps: a button, hittable, labelled with its tab's title ("Cart, 1
    /// item" with one item in the cart), Selected when its tab is in front, and a tap on it opens that tab's first
    /// screen. The bar is not on the screens below a tab. Every problem is listed, then the test fails once.
    func testEveryTabIsTheButtonAPersonTaps() {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launch()
        app.signIn()
        var problems: [String] = []
        let tabs = [("nav_cart", "Cart", "cart_screen"), ("nav_lab", "Lab", "lab_screen"),
                    ("nav_settings", "Settings", "settings_screen"), ("nav_shop", "Shop", "shop_screen")]
        func check(_ id: String, label: String, selected: Bool) {
            let tab = app.id(id)
            let there = tab.appears(timeout: looksTimeout)
            guard there.met else { problems.append("\(id): not in the tree " + there.said); return }
            if tab.elementType != .button { problems.append("\(id): a \(tab.elementType.rawValue), not a button") }
            if !tab.isHittable { problems.append("\(id): not hittable at \(tab.frame)") }
            if tab.label != label { problems.append("\(id): labelled \"\(tab.label)\", not \"\(label)\"") }
            if tab.isSelected != selected { problems.append("\(id): \(selected ? "not " : "")selected") }
        }
        XCTContext.runActivity(named: "Each tab, tapped") { _ in
            for (id, _, screen) in tabs {
                let there = app.id(id).appears(timeout: looksTimeout)
                guard there.met else { problems.append("\(id): not in the tree " + there.said); continue }
                app.id(id).tap()
                let opened = app.id(screen).appears(timeout: looksTimeout)
                if !opened.met { problems.append("\(id): a tap did not open \(screen): " + opened.said + "; then on screen: " + app.screens()) }
                for (other, otherTitle, _) in tabs { check(other, label: otherTitle, selected: other == id) }
            }
        }
        XCTContext.runActivity(named: "The Cart tab says its count") { _ in
            app.id("shop_item_1").tapWhenThere()
            if app.id("nav_shop").exists { problems.append("the tab bar is on the item page") }
            app.id("item_add_to_cart").tapWhenThere()
            app.back()
            check("nav_cart", label: "Cart, 1 item", selected: false)
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "the tab bar"
        shot.lifetime = problems.isEmpty ? .deleteOnSuccess : .keepAlways
        add(shot)
        // a missing tab is met on every round of the loop: each problem once, in the order found
        let listed = problems.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        if !listed.isEmpty {
            XCTFail("\(listed.count) tab problem(s):\n" + listed.joined(separator: "\n"))
        }
    }

    /// The walk names every native id of the list at least once (templates by one instance or more).
    func testTheWalkCoversEveryId() {
        // AMENDED (1.2): a spinner's ids are checked by the step's look for its spinner
        let walked = (Self.signedOut + Self.shopAndCart + Self.labBenches + Self.settingsAndStates + Self.lobby("lab_lobby"))
            .flatMap { $0.ids + ($0.spinner?.ids ?? []) }
        let missing = SpecIds.shared.native.map(\.id).filter { entry in !walked.contains { SpecIds.matches($0, entry) } }
        XCTAssertEqual(missing, [], "ids the walk never checks")
        let unknown = walked.filter { id in !SpecIds.shared.native.contains { SpecIds.matches(id, $0.id) } }
        XCTAssertEqual(unknown, [], "ids the walk checks that are not in the list")
    }

    // MARK: Walking

    /// Walks every step, whatever an earlier one found, and checks every id of every step. The walk fails once, at
    /// its end, with every missing id and every id outside the list, screen by screen, and every tap or field it could
    /// not use on the way (`Misses`: a missing element no longer ends the walk, as `lab_webview` did in the third CI
    /// run). Each step's own activity carries its screenshot and what it found; a step that missed anything also keeps
    /// the whole tree XCUITest read, every element's type, identifier, label and frame, so the next run shows where an
    /// id went.
    private func walk(_ steps: [Step]) {
        continueAfterFailure = true
        Misses.keep()
        defer { Misses.stopKeeping() }
        let app = XCUIApplication()
        app.launch()
        var problems: [String] = []
        for step in steps {
            XCTContext.runActivity(named: step.name) { activity in
                step.act(app)
                // a banner first, before anything else spends its 10 s
                let started = Date()
                let banner = step.banner.map { app.looksForBanner(showing: $0.text) }
                var spinner = step.spinner.map { app.looksForSpinner($0) }
                var tries = spinner == nil ? 0 : 1
                if let wanted = step.spinner, let again = wanted.again {
                    while spinner?.met == false && tries < wanted.attempts {
                        again(app, tries)
                        spinner = app.looksForSpinner(wanted)
                        tries += 1
                    }
                }
                if let looks = banner, !looks.met {
                    problems.append("\(step.name): no banner after the action: snackbar_text never showed "
                                    + "\"\(step.banner?.text ?? "")\" with snackbar around it \(looks.said)")
                }
                if let looks = spinner {
                    let ids = step.spinner?.ids.joined(separator: " ") ?? ""
                    let said = looks.met
                        ? "\(ids) seen " + String(format: "%.1f", looks.looks.last?.after ?? 0) + " s after the action that brought it (try \(tries))"
                        : "\(ids) never seen in \(tries) tries, the last \(looks.said): a look that came after the spinner's second, not a missing id"
                    print("WALK: \(step.name): \(said)")
                    XCTContext.runActivity(named: said) { _ in }
                }
                let seenInTheBanner = banner?.met == true ? Set(Banner.ids) : []
                app.answerSavePasswordCard()
                let couldNot = Misses.take()
                if !couldNot.isEmpty { problems.append("\(step.name): \(couldNot.joined(separator: "; "))") }
                // One read of the whole tree first, at once: a spinner's id lasts 3 s, and waiting on each id in turn
                // spent them before it was the spinner's turn (second CI run: slow_loading). Only what that read
                // missed is waited for, but for a banner's ids that its own look saw.
                let first = Set(app.identifiers())
                let read = Date().timeIntervalSince(started)
                let gone = step.ids.filter { !first.contains($0) && seenInTheBanner.contains($0) }
                let missing = step.ids.filter { !first.contains($0) && !seenInTheBanner.contains($0)
                                                && !app.id($0).appears(timeout: looksTimeout).met }
                if let looks = banner, looks.met {
                    let seen = String(format: "%.1f", looks.looks.last?.after ?? 0)
                    let words = "\(Banner.ids.joined(separator: " ")) seen showing \"\(step.banner?.text ?? "")\" \(seen) s "
                        + "after the action" + (gone.isEmpty ? "" : String(format: "; gone by the walk's read of the "
                        + "tree %.1f s after it: a banner that had already gone, not a missing id", read))
                    XCTContext.runActivity(named: words) { _ in }
                }
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
                let clean = missing.isEmpty && outside.isEmpty && couldNot.isEmpty && banner?.met != false && spinner?.met != false
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = step.name
                shot.lifetime = clean ? .deleteOnSuccess : .keepAlways
                activity.add(shot)
                if !clean {
                    let whole = XCTAttachment(string: app.debugDescription)
                    whole.name = "\(step.name): the tree"
                    whole.lifetime = .keepAlways
                    activity.add(whole)
                }
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

extension XCUIApplication {
    /// Looks until every one of the spinner's ids is in the tree, for `feedSpinnerLook`; every look kept. A look is one
    /// `exists` per id, not a snapshot, so each look is as short as XCUITest makes it.
    func looksForSpinner(_ spinner: IdWalkTests.Spinner) -> Looks {
        Looks.until(timeout: feedSpinnerLook) {
            let missing = spinner.ids.filter { !id($0).exists }
            return (missing.isEmpty ? XCUIElement.present : "not in the tree: " + missing.joined(separator: " "), missing.isEmpty)
        }
    }

    /// Looks until `snackbar_text` shows exactly `text` with `snackbar` in the tree, for `looksTimeout`; every look kept.
    func looksForBanner(showing text: String) -> Looks {
        let label = id("snackbar_text")
        let box = id("snackbar")
        return Looks.until(timeout: looksTimeout) {
            let (now, there) = label.glance()
            guard let now else { return (there ? XCUIElement.several : XCUIElement.absent, false) }
            let around = box.exists
            return (now.label + (around ? "" : " (no snackbar around it)"), now.label == text && around)
        }
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
        id("signin_email").mustAppear(timeout: 15, "the sign-in screen: signin_email")
        id("signin_use_test_account").tapWhenThere()
        id("signin_submit").tapWhenThere()
    }
}

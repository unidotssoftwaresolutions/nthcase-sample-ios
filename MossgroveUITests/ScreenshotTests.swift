import XCTest

/// Every screen of the app, as round one named them (`docs/screenshots/{light,dark}/NN-name.png`). The run's theme is
/// the simulator's own appearance, which CI sets before each run (`xcrun simctl ui <udid> appearance dark`).
///
/// With `MOSSGROVE_SCREENSHOTS` set (CI passes `TEST_RUNNER_MOSSGROVE_SCREENSHOTS`), the pictures are written there as
/// PNG files; they are always kept as attachments of the result bundle too.
///
/// The 32 screens are twelve tests, each from a cold start, so a screen that fails costs only its own group: the run
/// still makes every other picture. `scripts/ci-screenshots.sh` checks that all 32 files are there and names any
/// that is not. 25–31 are the Lobby (1.1), in SwiftUI and in UIKit, with the pager on and off; 27 shows the quick
/// sheet's More like this (1.2); 32 is the Feed (1.2).
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var folder: URL?

    override func setUp() {
        continueAfterFailure = false
        if let path = ProcessInfo.processInfo.environment["MOSSGROVE_SCREENSHOTS"], !path.isEmpty {
            folder = URL(fileURLWithPath: path)
            try? FileManager.default.createDirectory(at: folder!, withIntermediateDirectories: true)
        }
        app = XCUIApplication()
        app.launch()
    }

    private func shot(_ name: String, settle: TimeInterval = 0.6) {
        Thread.sleep(forTimeInterval: settle)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let folder {
            XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: folder.appendingPathComponent("\(name).png")))
        }
    }

    /// The element is in the tree; a failure lists every look and the screen after them.
    private func wait(_ id: String, _ timeout: TimeInterval = looksTimeout, file: StaticString = #filePath, line: UInt = #line) {
        app.id(id).mustAppear(timeout: timeout, id, file: file, line: line)
    }

    func test01SignIn() {
        wait("signin_screen", 15)
        shot("01-sign-in")

        app.id("signin_email").type("tester@mossgrove.test\n")
        app.id("signin_password").type("letmein1")
        app.id("signin_submit").tapWhenThere()
        wait("signin_error")
        shot("02-sign-in-error")
    }

    func test02Shop() {
        app.signIn()
        wait("shop_item_1")
        shot("03-shop")

        app.id("shop_search").type("lamp\n")
        wait("shop_item_5")
        shot("04-shop-search")

        app.id("shop_search").replace(with: "velvet\n")
        wait("shop_empty")
        shot("05-shop-no-match")
    }

    func test03ItemCartAndOrders() {
        app.signIn()
        app.id("shop_item_1").tapWhenThere()
        wait("item_add_to_cart")
        shot("06-item")

        app.id("item_qty_increase").tapWhenThere()
        app.id("item_add_to_cart").tapWhenThere()
        wait("snackbar")
        shot("07-item-snackbar")

        app.id("snackbar_action").tapWhenThere()
        wait("cart_total")
        shot("08-cart")

        app.id("cart_checkout").tapWhenThere()
        wait("dialog")
        shot("09-cart-dialog")

        app.id("dialog_confirm").tapWhenThere()
        wait("cart_empty")
        shot("10-cart-empty")

        // "View orders" in the snackbar: the same Orders screen the Lab opens, with Order 1 in it
        app.id("snackbar_action").tapWhenThere()
        wait("orders_row_1")
        shot("18-orders")
    }

    func test04Form() {
        app.signIn()
        app.openTab("nav_lab")
        wait("lab_gift_cards")
        shot("11-lab")

        app.id("lab_form").tapWhenThere()
        app.scrollTo(app.id("form_submit")).tapWhenThere()
        wait("form_terms_error")
        app.scrollTo(app.id("form_name"), up: true)
        shot("12-form-errors")

        app.id("form_name").type("Sam Rivera\n")
        app.id("form_email").type("sam@example.test\n")
        app.id("form_age").type("34")
        app.id("form_password").type("garden42x\n")
        app.scrollTo(app.id("form_category")).tapWhenThere()
        app.id("form_category_option_garden").tapWhenThere()
        app.scrollTo(app.id("form_date")).tapWhenThere()
        app.id("form_date_confirm").tapWhenThere()
        app.id("form_budget").adjust(toNormalizedSliderPosition: 0.6)
        app.scrollTo(app.id("form_terms")).tapWhenThere()
        app.scrollTo(app.id("form_submit")).tapWhenThere()
        wait("form_result")
        app.scrollTo(app.id("form_result"))
        shot("13-form-done")
    }

    // The Lab's three benches are three tests, each from a cold start: in the third CI run a care guide that did not
    // open cost the slots' two pictures after it.
    func test05Gestures() {
        app.signIn()
        app.openLab("lab_gestures")
        wait("gestures_status")
        shot("14-gestures")
    }

    func test05WebView() {
        app.signIn()
        app.openLab("lab_webview")
        // In build run 44486580432 this was XCTest's 10 s wait: it made one look, which saw "Loading the care guide…",
        // and never looked again; the page loaded 5.4 to 5.7 s after the tap (see `careGuideTimeout`)
        app.id("webview_status").mustContain("Care guide loaded", timeout: careGuideTimeout, "the care guide's webview_status")
        shot("15-webview", settle: 1.0)
    }

    func test05Slots() {
        app.signIn()
        app.openLab("lab_slow")
        // 3 s, the spinner's whole life (`slowLoad`): a later look could not find it. A look begun within the 3 s is read.
        wait("slow_loading", slowLoad)
        shot("16-slow-loading", settle: 0.2)

        wait("slow_content", slowLoad + looksTimeout)
        shot("17-slow-done")
    }

    func test06SettingsAndOrderStates() {
        app.signIn()
        app.openTab("nav_settings")
        wait("settings_theme")
        shot("22-settings")

        app.scrollTo(app.id("settings_reset")).tapWhenThere()
        app.alerts.firstMatch.mustAppear("the Reset settings alert")
        shot("23-settings-dialog")

        let confirm = app.id("settings_reset_confirm")
        (confirm.exists ? confirm : app.alerts.buttons["Empty"]).tap()
        app.scrollTo(app.id("settings_fail_loading")).set(true)
        app.openLab("lab_orders")
        wait("orders_error")
        shot("20-orders-error")

        app.id("orders_retry").tapWhenThere()
        wait("orders_empty")
        shot("19-orders-empty")
    }

    func test07GiftCards() {
        app.signIn()
        app.openLab("lab_gift_cards")
        app.text("Check a balance").mustAppear("\"Check a balance\"")
        app.buttons.matching(NSPredicate(format: "label == 'Choose'")).allElementsBoundByIndex
            .min { $0.frame.minX < $1.frame.minX }?.tap()
        app.text("with the Fern design").mustAppear("\"with the Fern design\" after Choose")
        shot("21-gift-cards")
    }

    func test08DeepLinkUnknown() {
        app.signIn()
        app.openLinkWhileRunning("nthcase-sample://item/999")
        wait("item_not_found")
        shot("24-deep-link-unknown")
    }

    /// The Lobby's seven, under the Android app's names: 25–27 and 30 the SwiftUI Lobby, 28, 29 and 31 the UIKit one
    /// ("views", as Android calls its classic-toolkit Lobby).
    func test09Lobby() {
        app.signIn()
        openLobby("lab_lobby")
        shot("25-lobby")
        boardCellTapped()
        shot("26-lobby-board")
        app.scrollLobbyPage(until: app.id("lobby_row_1_tile_1"), up: true)
        app.longPressWhenThere(app.id("lobby_row_1_tile_1"))
        wait("lobby_sheet_rate")
        shot("27-lobby-sheet", settle: 1.0)
        app.id("lobby_sheet_rate").tapWhenThere()
        app.id("lobby_sheet").mustVanish("the quick sheet after Rate")
        pagerOff()
        shot("30-lobby-no-pager")
        leaveLobby()

        openLobby("lab_lobby_views")
        shot("28-lobby-views")
        boardCellTapped()
        shot("29-lobby-views-board")
        app.scrollLobbyPage(until: app.id("lobby_row_1_tile_1"), up: true)
        pagerOff()
        shot("31-lobby-views-no-pager")
        leaveLobby()
    }

    /// The Feed (1.2), as it opens: rows 1 to 20, the first of them on screen.
    func test10Feed() {
        app.signIn()
        app.openLab("lab_feed")
        wait("feed_list")
        wait("feed_row_1")
        shot("32-feed")
    }

    private func openLobby(_ bench: String) {
        app.openLab(bench)
        wait("lobby_pager")
        wait("lobby_bar_saved")
    }

    /// The page down to the board, and one cell of it tapped, so the log shows a line.
    ///
    /// The page is moved gently, as the id walk reaches the board: drags that do not fling, each shorter than the
    /// page's window, and back toward the cell if it has gone past. In CI run 44365074289 (light) the UIKit page's fifth
    /// flung drag stopped with B2 in the tree but above the page's 258-point window (cell at y 426.7–482.7, window from
    /// 529), so it was never hittable; the 20 drags left all went down, to the page's end, and XCUITest's own tap could
    /// not bring it back (its scroll to visible ended with no hit point; the cell sits in the board, a scroller of its
    /// own inside the page). The same five drags had stopped with B2 in the window in dark, and in both themes on the
    /// run before. SwiftUI's page (176 points with the pager on) had the same risk.
    private func boardCellTapped() {
        app.scrollLobbyPage(until: app.id("lobby_board_cell_b2"), gently: true)
        app.id("lobby_board_cell_b2").tapWhenThere()
        app.id("lobby_touch_log").mustShow("Tapped: B2 (board)", timeout: looksTimeout, "the tap on B2; lobby_touch_log")
    }

    private func pagerOff() {
        app.id("lobby_pager_shown").set(false)
        app.id("lobby_pager").mustVanish("the pager with Show the pager off")
    }

    /// Show the pager is kept until the app closes: it is put back on for the next Lobby.
    private func leaveLobby() {
        app.id("lobby_pager_shown").set(true)
        app.back()
    }
}

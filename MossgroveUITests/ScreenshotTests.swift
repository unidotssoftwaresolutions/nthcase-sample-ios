import XCTest

/// Every screen of the app, as round one named them (`docs/screenshots/{light,dark}/NN-name.png`). The run's theme is
/// the simulator's own appearance, which CI sets before each run (`xcrun simctl ui <udid> appearance dark`).
///
/// With `MOSSGROVE_SCREENSHOTS` set (CI passes `TEST_RUNNER_MOSSGROVE_SCREENSHOTS`), the pictures are written there as
/// PNG files; they are always kept as attachments of the result bundle too.
///
/// The 24 screens are eight tests, each from a cold start, so a screen that fails costs only its own group: the run
/// still makes every other picture. `scripts/ci-screenshots.sh` checks that all 24 files are there and names any
/// that is not.
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

    private func wait(_ id: String, _ timeout: TimeInterval = 8) {
        XCTAssertTrue(app.id(id).waitForExistence(timeout: timeout), "\(id) did not appear")
    }

    func test01SignIn() {
        wait("signin_screen", 15)
        shot("01-sign-in")

        app.id("signin_email").type("tester@mossgrove.test\n")
        app.id("signin_password").type("letmein1")
        app.id("signin_submit").tap()
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
        app.id("shop_item_1").tap()
        wait("item_add_to_cart")
        shot("06-item")

        app.id("item_qty_increase").tap()
        app.id("item_add_to_cart").tap()
        wait("snackbar")
        shot("07-item-snackbar")

        app.id("snackbar_action").tap()
        wait("cart_total")
        shot("08-cart")

        app.id("cart_checkout").tap()
        wait("dialog")
        shot("09-cart-dialog")

        app.id("dialog_confirm").tap()
        wait("cart_empty")
        shot("10-cart-empty")

        // "View orders" in the snackbar: the same Orders screen the Lab opens, with Order 1 in it
        app.id("snackbar_action").tap()
        wait("orders_row_1")
        shot("18-orders")
    }

    func test04Form() {
        app.signIn()
        app.openTab("nav_lab")
        wait("lab_gift_cards")
        shot("11-lab")

        app.id("lab_form").tap()
        app.scrollTo(app.id("form_submit")).tap()
        wait("form_terms_error")
        app.scrollTo(app.id("form_name"), up: true)
        shot("12-form-errors")

        app.id("form_name").type("Sam Rivera\n")
        app.id("form_email").type("sam@example.test\n")
        app.id("form_age").type("34")
        app.id("form_password").type("garden42x\n")
        app.scrollTo(app.id("form_category")).tap()
        app.id("form_category_option_garden").tap()
        app.scrollTo(app.id("form_date")).tap()
        app.id("form_date_confirm").tap()
        app.id("form_budget").adjust(toNormalizedSliderPosition: 0.6)
        app.scrollTo(app.id("form_terms")).tap()
        app.scrollTo(app.id("form_submit")).tap()
        wait("form_result")
        app.scrollTo(app.id("form_result"))
        shot("13-form-done")
    }

    func test05LabBenches() {
        app.signIn()
        app.openLab("lab_gestures")
        wait("gestures_status")
        shot("14-gestures")

        app.back()
        app.id("lab_webview").tap()
        XCTAssertTrue(app.id("webview_status").waitFor("Care guide loaded", timeout: 10))
        shot("15-webview", settle: 1.0)

        app.back()
        app.id("lab_slow").tap()
        wait("slow_loading", 3)
        shot("16-slow-loading", settle: 0.2)

        wait("slow_content")
        shot("17-slow-done")
    }

    func test06SettingsAndOrderStates() {
        app.signIn()
        app.openTab("nav_settings")
        wait("settings_theme")
        shot("22-settings")

        app.scrollTo(app.id("settings_reset")).tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        shot("23-settings-dialog")

        let confirm = app.id("settings_reset_confirm")
        (confirm.exists ? confirm : app.alerts.buttons["Empty"]).tap()
        app.scrollTo(app.id("settings_fail_loading")).set(true)
        app.openLab("lab_orders")
        wait("orders_error")
        shot("20-orders-error")

        app.id("orders_retry").tap()
        wait("orders_empty")
        shot("19-orders-empty")
    }

    func test07GiftCards() {
        app.signIn()
        app.openLab("lab_gift_cards")
        XCTAssertTrue(app.text("Check a balance").waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label == 'Choose'")).allElementsBoundByIndex
            .min { $0.frame.minX < $1.frame.minX }?.tap()
        XCTAssertTrue(app.text("with the Fern design").waitForExistence(timeout: 5))
        shot("21-gift-cards")
    }

    func test08DeepLinkUnknown() {
        app.signIn()
        app.openLinkWhileRunning("nthcase-sample://item/999")
        wait("item_not_found")
        shot("24-deep-link-unknown")
    }
}

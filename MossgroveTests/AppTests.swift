import MossgroveKit
import UIKit
import XCTest
@testable import Mossgrove

/// Unit tests that run inside the app on a simulator (CI only): the app's model, the UIKit screen's ids, the shake
/// and the alert's button ids, on the iOS version the run uses.
@MainActor
final class AppModelTests: XCTestCase {
    func testColdStartIsSignedOutAndEmpty() {
        let model = AppModel()
        XCTAssertFalse(model.signedIn)
        XCTAssertTrue(model.cart.isEmpty)
        XCTAssertTrue(model.orders.isEmpty)
        XCTAssertFalse(model.slowLoading)
        XCTAssertFalse(model.failFirstLoad)
        XCTAssertFalse(model.orderUpdates)
        XCTAssertEqual(model.themeMode, .system)
    }

    func testADeepLinkBeforeSignInOpensRightAfterIt() {
        let model = AppModel()
        model.open(url: URL(string: "nthcase-sample://item/7")!)
        XCTAssertFalse(model.signedIn)
        model.signIn(email: "  Tester@Mossgrove.test ")
        XCTAssertEqual(model.signedInEmail, "tester@mossgrove.test")
        XCTAssertEqual(model.navigation.selected, .shop)
        XCTAssertEqual(model.navigation.path(.shop), [.item("7")])
        model.open(url: URL(string: "nthcase-sample://cart/1")!)
        XCTAssertEqual(model.navigation.path(.shop), [.item("7")], "any other host is ignored")
    }

    func testReselectingATabResetsIt() {
        let model = AppModel()
        model.signIn(email: Account.email)
        model.navigation.select(.lab)
        model.navigation.push(.gestures)
        model.navigation.select(.cart)
        model.navigation.select(.lab)
        XCTAssertEqual(model.navigation.path(.lab), [])
    }

    func testOrdersAreNumberedNewestFirstAndSignOutClearsEverything() {
        let model = AppModel()
        model.signIn(email: Account.email)
        model.add(1, quantity: 2)
        XCTAssertEqual(model.placeOrder().number, 1)
        model.add(5, quantity: 1)
        XCTAssertEqual(model.placeOrder().number, 2)
        XCTAssertEqual(model.orders.map(\.number), [2, 1])
        XCTAssertTrue(model.cart.isEmpty)
        model.add(3, quantity: 1)
        model.signOut()
        XCTAssertFalse(model.signedIn)
        XCTAssertTrue(model.cart.isEmpty)
        XCTAssertTrue(model.orders.isEmpty)
        XCTAssertEqual(model.navigation, TabNavigation())
    }

    func testASnackbarReplacesTheLastAndItsActionRuns() {
        let model = AppModel()
        var ran = false
        model.showSnack("One")
        model.showSnack(Texts.addedToCart, actionLabel: Texts.viewCart) { ran = true }
        XCTAssertEqual(model.snack?.message, "Added to cart")
        model.performSnackAction()
        XCTAssertTrue(ran)
        XCTAssertNil(model.snack)
        XCTAssertEqual(AppModel.snackSeconds, 10)
    }
}

@MainActor
final class SettingsScreenTests: XCTestCase {
    /// Every `settings_*` id of the list is on the UIKit screen, except the two that live in its dialog.
    func testTheUIKitScreenCarriesItsIds() throws {
        let model = AppModel()
        model.signIn(email: Account.email)
        let controller = SettingsViewController(model: model)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 2400)
        controller.view.layoutIfNeeded()
        let ids = identifiers(in: controller.view)
        let expected: Set = [
            TestIds.settingsScreen, TestIds.settingsAccountEmail, TestIds.settingsOrders, TestIds.settingsSignOut,
            TestIds.settingsTheme, TestIds.settingsThemeSystem, TestIds.settingsThemeLight, TestIds.settingsThemeDark,
            TestIds.settingsNotifications, TestIds.settingsNotificationsStatus, TestIds.settingsSendNotification,
            TestIds.settingsSlowLoading, TestIds.settingsFailLoading, TestIds.settingsReset, TestIds.settingsVersion,
        ]
        XCTAssertEqual(expected.subtracting(ids), [], "missing on the UIKit screen")
    }

    /// The reset dialog's two buttons get their ids once the alert is on screen.
    func testTheAlertButtonsGetTheirIds() throws {
        let alert = UIAlertController(title: Texts.resetTitle, message: Texts.resetBody, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Texts.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Texts.resetConfirm, style: .destructive))
        let host = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController)
        let shown = expectation(description: "alert shown")
        host.present(alert, animated: false) { shown.fulfill() }
        wait(for: [shown], timeout: 5)
        AlertIds.name(alert, [Texts.cancel: TestIds.settingsResetCancel, Texts.resetConfirm: TestIds.settingsResetConfirm])
        let ids = identifiers(in: alert.view)
        XCTAssertTrue(ids.contains(TestIds.settingsResetCancel), "Cancel has no id")
        XCTAssertTrue(ids.contains(TestIds.settingsResetConfirm), "Empty has no id")
        let gone = expectation(description: "alert dismissed")
        alert.dismiss(animated: false) { gone.fulfill() }
        wait(for: [gone], timeout: 5)
    }

    private func identifiers(in view: UIView) -> Set<String> {
        var ids: Set<String> = []
        if let id = view.accessibilityIdentifier, !id.isEmpty { ids.insert(id) }
        if let cell = view as? UITableViewCell, let id = cell.textLabel?.accessibilityIdentifier { ids.insert(id) }
        for sub in view.subviews { ids.formUnion(identifiers(in: sub)) }
        return ids
    }
}

@MainActor
final class ShakeTests: XCTestCase {
    /// iOS's own shake, which the Simulator's Shake and NthCase's `shake` produce, says "Shaken".
    func testTheSystemShakeIsCaught() {
        var status = GestureWords.ready
        let catcher = ShakeCatcher.Catcher { status = GestureWords.shaken }
        catcher.motionEnded(.motionShake, with: nil)
        XCTAssertEqual(status, "Shaken")
    }
}

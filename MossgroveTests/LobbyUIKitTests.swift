import MossgroveKit
import UIKit
import XCTest
@testable import Mossgrove

/// The UIKit Lobby's view tree, inside the app on a simulator (CI only): what leaves the tree really leaves its
/// superview, and the scrollers are in the order the spec asks. XCUITest's tree, which Appium reads, is LobbyTests'.
@MainActor
final class LobbyUIKitTests: XCTestCase {
    private func open(delay: Int = 0, pager: Bool = true) -> LobbyViewController {
        let model = AppModel()
        model.lobbySavedDelay = delay
        model.lobbyPagerShown = pager
        let controller = LobbyViewController(model: model)
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()
        return controller
    }

    /// Every identifier in the view tree, depth first in subview order.
    private func identifiers(in view: UIView) -> [String] {
        var ids: [String] = []
        if let id = view.accessibilityIdentifier, !id.isEmpty { ids.append(id) }
        for sub in view.subviews { ids += identifiers(in: sub) }
        return ids
    }

    func testTheFixedPartsCarryTheirIds() {
        let ids = Set(identifiers(in: open().view))
        let expected: Set = [
            TestIds.lobbyScreen, TestIds.lobbyTouchLog, TestIds.lobbyTouchCount, TestIds.lobbyTouchReset, TestIds.lobbySavedDelay,
            TestIds.lobbySavedDelayChoice(0), TestIds.lobbySavedDelayChoice(12), TestIds.lobbyPagerShown, TestIds.lobbyPager,
            TestIds.lobbyPagerPosition, TestIds.lobbyPagerAuto, TestIds.lobbyTopRowPosition, TestIds.lobbyTopRow, TestIds.lobbyPage,
            TestIds.lobbyBar, TestIds.lobbyBarHome, TestIds.lobbyBarLive, TestIds.lobbyBarSaved, TestIds.lobbyBarOffers,
        ]
        XCTAssertEqual(expected.subtracting(ids), [], "missing on the UIKit Lobby")
    }

    /// With the pager on, the pager's view comes before the Top 10 row's, which comes before the page's. Off, the
    /// pager, its position line and Auto-advance are in no view of the tree.
    func testTheScrollersOrderAndThePagerLeaving() {
        let scrollers = [TestIds.lobbyPager, TestIds.lobbyTopRow, TestIds.lobbyPage]
        let on = identifiers(in: open().view).filter(scrollers.contains)
        XCTAssertEqual(on, scrollers)
        let offIds = identifiers(in: open(pager: false).view)
        XCTAssertEqual(offIds.filter(scrollers.contains), [TestIds.lobbyTopRow, TestIds.lobbyPage])
        for gone in [TestIds.lobbyPager, TestIds.lobbyPagerPosition, TestIds.lobbyPagerAuto] {
            XCTAssertFalse(offIds.contains(gone), "\(gone) is still a view with the pager off")
        }
    }

    /// Show the pager switched off and on again, as a person does it: the pager is back in its own place, before the
    /// Top 10 row, and gone again when switched off a second time.
    func testThePagerComesBackInItsPlace() {
        let scrollers = [TestIds.lobbyPager, TestIds.lobbyTopRow, TestIds.lobbyPage]
        let controller = open()
        guard let toggle = controller.view.findView(TestIds.lobbyPagerShown) as? UISwitch else {
            return XCTFail("no switch named \(TestIds.lobbyPagerShown)")
        }
        for (on, expected) in [(false, [TestIds.lobbyTopRow, TestIds.lobbyPage]), (true, scrollers),
                               (false, [TestIds.lobbyTopRow, TestIds.lobbyPage]), (true, scrollers)] {
            toggle.isOn = on
            toggle.sendActions(for: .valueChanged)
            controller.view.layoutIfNeeded()
            XCTAssertEqual(identifiers(in: controller.view).filter(scrollers.contains), expected, "with Show the pager \(on ? "on" : "off")")
        }
    }

    /// Before its delay, Saved is not a view of the bar at all: three buttons, and no view named lobby_bar_saved.
    func testSavedIsNoViewBeforeItsDelay() {
        let controller = open(delay: 12)
        XCTAssertFalse(identifiers(in: controller.view).contains(TestIds.lobbyBarSaved))
        let bar = controller.view.findView(TestIds.lobbyBar) as? UIStackView
        XCTAssertEqual(bar?.arrangedSubviews.count, 3)
        XCTAssertEqual(bar?.subviews.count, 3)
    }
}

private extension UIView {
    func findView(_ id: String) -> UIView? {
        if accessibilityIdentifier == id { return self }
        for sub in subviews { if let found = sub.findView(id) { return found } }
        return nil
    }
}

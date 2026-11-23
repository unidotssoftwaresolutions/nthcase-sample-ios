import MossgroveKit
import SwiftUI
import UIKit
import XCTest
@testable import Mossgrove

/// The Feed (SPEC.md §5, 1.2) inside the app on a simulator, laid out by SwiftUI and timed by the app's own clock: no
/// gesture, no look from outside. A window tall enough to show row 18 starts a load at once; its spinner row lasts its
/// second; then 20 more rows come, and no more while row 38 does not show. A phone's window starts none until scrolled.
///
/// The UI tests cannot promise this second: on a busy simulator XCUITest took 2.5 to 3.5 s to make one quarter-second
/// stroke and up to 1.8 s for one look (the first local run), so a spinner that lasts 1 s is often gone when it looks.
@MainActor
final class FeedViewTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// The Feed in a window of its own, `height` points tall, inside a navigation stack as the app shows it.
    private func show(height: CGFloat) throws -> FeedModel {
        let model = FeedModel()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first, "no window scene")
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: height)
        window.rootViewController = UIHostingController(rootView: NavigationStack { FeedView(model: model) })
        window.isHidden = false
        self.window = window
        return model
    }

    /// Lets the main run loop turn for `seconds`: SwiftUI lays out, and the Feed's own task sleeps and wakes.
    private func pass(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    func testATallWindowStartsALoadAtOnceAndItsRowsComeASecondLater() throws {
        // 1,600 points: rows to about 26 show at open, so row 18 does
        let model = try show(height: 1_600)
        pass(0.3)
        XCTAssertTrue(model.state.loading, "no load with row 18 in sight")
        XCTAssertEqual(model.state.count, 20, "the rows came before the spinner row's second")
        pass(0.4)
        XCTAssertTrue(model.state.loading, "the spinner row went before its second")
        XCTAssertEqual(model.state.count, 20)
        pass(0.8)
        XCTAssertFalse(model.state.loading, "the spinner row still there 1.5 s on")
        XCTAssertEqual(model.state.count, 40, "20 more rows after the second")
        // row 38's top is 2,072 points down the list: it does not show, so nothing more loads
        pass(1.5)
        XCTAssertFalse(model.state.loading)
        XCTAssertEqual(model.state.count, 40)
    }

    func testAPhonesWindowStartsNoLoadUntilTheListIsScrolled() throws {
        // 852 points, a phone's: rows to about 13 show
        let model = try show(height: 852)
        pass(1.5)
        XCTAssertFalse(model.state.loading, "a load started with row 18 out of sight")
        XCTAssertEqual(model.state.count, 20)
    }
}

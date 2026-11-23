import XCTest

/// The Lobby (SPEC.md §5, §12 and §13, new in 1.1), both builds, in the tree Appium's XCUITest driver reads: XCUITest's
/// own snapshot, the tree WebDriverAgent turns into Appium's page source, with `name` = the accessibility identifier.
///
/// Three things are proven here, and only on a simulator, so only in CI:
/// - **The order.** With the pager on, the first scroller in the tree is the pager, then the Top 10 row, then the
///   page. With it off, the pager and its position line are in no tree, and the first scroller is the Top 10 row.
///   "Scroller" means an element XCUITest types as a scroll view, a collection view, a table or a web view, the four
///   types WebDriverAgent scrolls in (`XCUIElement+FBScrolling.m`, `acceptedParents`).
/// - **Saved is absent before its delay.** No element anywhere answers to `lobby_bar_saved`, and the bar has three
///   buttons. That is also the look NthCase's iOS reach makes: `mobile: scroll {name: …}` asks WebDriverAgent for the
///   last descendant of the app with that identifier, and with none it answers "no such element" and makes no gesture.
/// - **The injected swipe.** The gesture WebDriverAgent 13.2.0 makes for `mobile: scroll` when it does scroll
///   (`XCUIElement+FBScrolling.m`): each drag presses for 0.5 s, drags at 300 points a second, and holds for 0.5 s,
///   from a quarter or three quarters into the scroller; a drag is at most three quarters of the scroller, and the rest
///   of the distance is a second drag. Two kinds are made, across the Top 10 row with the pager off and across row 1:
///   - **vertical**: `mobile: scroll {direction: down}` then `{direction: up}` on the row, the probe GuruAI's
///     TryScrollIntoView makes and the way UiScrollable swipes on Android;
///   - **along the row**: the drag `mobile: scroll {name}` makes to bring a tile to the right into view (half the row's
///     width, from three quarters across and a quarter down).
///   The test records what the touch log says after each. What it records is the finding: these tests fail only when
///   they cannot make the gesture.
///
/// Every finding is printed as one line starting `LOBBY:`, which the CI step copies into the run's summary.
final class LobbyTests: XCTestCase {
    static let swiftUI = "lab_lobby"
    static let uiKit = "lab_lobby_views"

    override func setUp() {
        continueAfterFailure = true
    }

    // MARK: The order, and what is absent

    func testTheOrderSwiftUI() { order(Self.swiftUI) }
    func testTheOrderUIKit() { order(Self.uiKit) }

    func testSavedComesLateSwiftUI() { savedComesLate(Self.swiftUI) }
    func testSavedComesLateUIKit() { savedComesLate(Self.uiKit) }

    // MARK: The injected swipe

    func testSwipeAcrossTheTopRowSwiftUI() { swipe(Self.swiftUI, across: "lobby_top_row", pagerOff: true, Self.vertical) }
    func testSwipeAcrossTheTopRowUIKit() { swipe(Self.uiKit, across: "lobby_top_row", pagerOff: true, Self.vertical) }
    func testSwipeAcrossRowOneSwiftUI() { swipe(Self.swiftUI, across: "lobby_row_1", pagerOff: false, Self.vertical) }
    func testSwipeAcrossRowOneUIKit() { swipe(Self.uiKit, across: "lobby_row_1", pagerOff: false, Self.vertical) }
    func testScrollAlongTheTopRowSwiftUI() { swipe(Self.swiftUI, across: "lobby_top_row", pagerOff: true, Self.along) }
    func testScrollAlongTheTopRowUIKit() { swipe(Self.uiKit, across: "lobby_top_row", pagerOff: true, Self.along) }
    func testScrollAlongRowOneSwiftUI() { swipe(Self.swiftUI, across: "lobby_row_1", pagerOff: false, Self.along) }
    func testScrollAlongRowOneUIKit() { swipe(Self.uiKit, across: "lobby_row_1", pagerOff: false, Self.along) }

    // MARK: The sheet that scrolls (1.2)

    func testMoreLikeThisScrollsInsideTheSheetSwiftUI() { moreLikeThis(Self.swiftUI) }
    func testMoreLikeThisScrollsInsideTheSheetUIKit() { moreLikeThis(Self.uiKit) }

    /// `mobile: scroll {direction: down}`, then `{direction: up}`: a vector of the scroller's whole height (distance 1.0).
    static let vertical: [(name: String, vector: (CGRect) -> CGVector)] = [
        ("down", { CGVector(dx: 0, dy: -$0.height) }),
        ("up", { CGVector(dx: 0, dy: $0.height) }),
    ]

    /// `fb_scrollToVisible` toward a tile to the right: `fb_scrollRightByNormalizedDistance(0.5)`.
    static let along: [(name: String, vector: (CGRect) -> CGVector)] = [
        ("along the row, toward a tile to the right", { CGVector(dx: -$0.width * 0.5, dy: 0) }),
    ]

    // MARK: Steps

    private func openLobby(_ bench: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        app.signIn()
        app.openLab(bench)
        app.id("lobby_touch_log").mustAppear("\(bench): the Lobby did not open; lobby_touch_log")
        app.id("lobby_page").mustAppear("\(bench): no page; lobby_page")
        return app
    }

    private func order(_ bench: String) {
        let app = openLobby(bench)
        let on = scrollers(app)
        report(bench, "pager on, scrollers in tree order: \(describe(on))")
        expectOrder(bench, on, ["lobby_pager", "lobby_top_row", "lobby_page"], "pager on")
        XCTAssertEqual(on.first?.identifier, "lobby_pager", "\(bench): the pager is not the first scroller: \(describe(on))")
        report(bench, "pager on, first XCUIElementTypeScrollView: \(on.first { $0.type == .scrollView }.map(describe) ?? "none")")

        app.id("lobby_pager_shown").set(false)
        let gone = ["lobby_pager", "lobby_pager_position", "lobby_pager_auto"] + (1...5).map { "lobby_banner_\($0)" }
        app.id("lobby_pager").mustVanish("\(bench): the pager with Show the pager off")
        let ids = Set(app.identifiers())
        XCTAssertEqual(gone.filter(ids.contains), [], "\(bench): in the tree with the pager off")
        let off = scrollers(app)
        report(bench, "pager off, scrollers in tree order: \(describe(off))")
        report(bench, "pager off, first XCUIElementTypeScrollView: \(off.first { $0.type == .scrollView }.map(describe) ?? "none")")
        XCTAssertEqual(off.first?.identifier, "lobby_top_row", "\(bench): the Top 10 row is not the first scroller: \(describe(off))")
        expectOrder(bench, off, ["lobby_top_row", "lobby_page"], "pager off")

        app.id("lobby_pager_shown").set(true)
        app.id("lobby_pager").mustAppear("\(bench): the pager did not come back")
        XCTAssertEqual(scrollers(app).first?.identifier, "lobby_pager", "\(bench): the pager is not first again")
        app.id("lobby_touch_log").mustShow("Nothing touched", timeout: looksTimeout, "\(bench): turning the pager touched something; lobby_touch_log")
        keepTree(app, "\(bench): the tree")
    }

    private func savedComesLate(_ bench: String) {
        let app = openLobby(bench)
        // 3 s, not `looksTimeout`: at 0 s Saved is there from the start, and a longer wait would pass a Saved that came
        // late. A look begun within the 3 s is read, however long it takes.
        app.id("lobby_bar_saved").mustAppear(timeout: 3, "\(bench): Saved is not there at 0 s")
        app.id("lobby_saved_delay_12").tapWhenThere()
        let chosen = Date()
        Thread.sleep(forTimeInterval: 1)
        // the look WebDriverAgent makes for `mobile: scroll {name: "lobby_bar_saved"}`: the app's last descendant
        // with that identifier
        let named = app.descendants(matching: .any).matching(identifier: "lobby_bar_saved").allElementsBoundByIndex
        XCTAssertEqual(named.count, 0, "\(bench): Saved is in the tree 1 s after choosing 12 s")
        let label = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Saved")).allElementsBoundByIndex
        XCTAssertEqual(label.count, 0, "\(bench): something labelled Saved is in the tree: \(label.map(\.identifier))")
        XCTAssertEqual(app.id("lobby_bar").buttons.count, 3, "\(bench): the bar does not have three buttons")
        report(bench, "12 s chosen: \(named.count) element named lobby_bar_saved, \(label.count) labelled Saved, "
               + "\(app.id("lobby_bar").buttons.count) bar buttons; the reach's mobile: scroll {name} finds nothing and makes no gesture")
        // 12 s for the delay and `looksTimeout` for the looks: in release run 44415519436 Saved was in the tree 14.3 s
        // after the choice, read by an existence check that took 6.2 s, inside a 15 s wait
        app.id("lobby_bar_saved").mustAppear(timeout: 12 + looksTimeout, "\(bench): Saved never came")
        let after = Date().timeIntervalSince(chosen)
        XCTAssertGreaterThan(after, 11.5, "\(bench): Saved came \(after) s after the choice")
        report(bench, String(format: "Saved in the tree %.1f s after choosing 12 s", after))
        XCTAssertEqual(app.id("lobby_bar").buttons.count, 4)
        // In release run 44415519436 this was a 2 s `waitFor`, which failed on its first look (see `waitFor`)
        app.id("lobby_touch_log").mustShow("Nothing touched", timeout: looksTimeout, "\(bench): the delay choice touched something; lobby_touch_log")
    }

    /// WebDriverAgent's scroll gestures on `scroller`, 0.25 s apart (GuruAI's PollIntervalMs between two of its probes),
    /// with the touch log read after each.
    private func swipe(_ bench: String, across scroller: String, pagerOff: Bool, _ gestures: [(name: String, vector: (CGRect) -> CGVector)]) {
        let app = openLobby(bench)
        if pagerOff {
            app.id("lobby_pager_shown").set(false)
            app.id("lobby_pager").mustVanish("\(bench): the pager with Show the pager off")
            XCTAssertEqual(scrollers(app).first?.identifier, "lobby_top_row", "\(bench): the Top 10 row is not first")
        }
        let target = app.id(scroller)
        let there = target.appears(timeout: looksTimeout)
        guard there.met else {
            XCTFail("\(bench): \(scroller) is not in the tree, so the gesture could not be made; " + there.said)
            keepTree(app, "\(bench): no \(scroller)")
            return
        }
        let positionId = scroller == "lobby_top_row" ? "lobby_top_row_position" : "lobby_row_1_position"
        for gesture in gestures {
            // the visible part of the scroller, as WebDriverAgent's scrollingFrame is
            let frame = target.frame.intersection(app.frame)
            let before = app.id(positionId).label
            let drags = Self.wdaDrags(frame: frame, vector: gesture.vector(frame))
            let under = drags.map { elementUnder(app, $0.from) }.joined(separator: "; then ")
            for drag in drags { Self.perform(app, drag) }
            Thread.sleep(forTimeInterval: 1.0)   // a tap counts only after the double-tap time; the sheet animates in
            let log = app.id("lobby_touch_log").exists ? app.id("lobby_touch_log").label : "(no log in the tree: a sheet is over it)"
            let count = app.id("lobby_touch_count").exists ? app.id("lobby_touch_count").label : "?"
            let open = ["lobby_detail", "lobby_promo", "lobby_sheet"].filter { app.id($0).exists }
            let after = app.id(positionId).exists ? app.id(positionId).label : "(not in the tree)"
            let strokes = drags.map { "(\(Int($0.from.x)),\(Int($0.from.y)))→(\(Int($0.to.x)),\(Int($0.to.y)))" }.joined(separator: " ")
            report(bench, "\(gesture.name) on \(scroller) (pager \(pagerOff ? "off" : "on")), \(drags.count) drag(s) \(strokes): pressed on \(under); "
                   + "log \"\(log.replacingOccurrences(of: "\n", with: " | "))\", \(count); open: \(open.isEmpty ? "nothing" : open.joined(separator: " ")); "
                   + "position \"\(before)\" → \"\(after)\"")
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "\(bench): after \(gesture.name) on \(scroller)"
            shot.lifetime = .keepAlways
            add(shot)
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    /// The quick sheet's More like this (SPEC.md §5, 1.2), from a long press on the Top 10 row's tile 2, which shows at
    /// once: the sheet opens at the medium detent with its first line in sight and its last one past its foot; drags
    /// inside `lobby_sheet_more` bring line 20 whole into it; the sheet does not move and nothing is touched on the way;
    /// the Lobby under the sheet is where it was; a tap on line 20 is logged as a button's and closes the sheet.
    private func moreLikeThis(_ bench: String) {
        let app = openLobby(bench)
        let topRow = app.id("lobby_top_row_position").label
        app.longPressWhenThere(app.id("lobby_top_row_tile_2"))
        let more = app.id("lobby_sheet_more")
        guard more.mustAppear("\(bench): the quick sheet has no More like this; lobby_sheet_more") else {
            keepTree(app, "\(bench): no lobby_sheet_more")
            return
        }
        app.id("lobby_sheet_more_row_1").mustShow("Like Pocket Notebook · 1 of 20", "\(bench): the sheet's first line")
        let sheet = app.id("lobby_sheet").frame
        let scroller = more.frame
        let last = app.id("lobby_sheet_more_row_20")
        let lastAtOpen = last.exists ? "in the tree at \(last.frame)" : "not in the tree"
        XCTAssertFalse(last.exists && scroller.contains(last.frame), "\(bench): line 20 is in sight at once: the lines do not run past the sheet's foot")
        XCTAssertLessThanOrEqual(scroller.maxY, app.frame.maxY + 0.5, "\(bench): the sheet's scroller runs below the screen")
        let drags = app.scrollInside(more, until: last)
        let whole = last.exists && more.frame.contains(last.frame)
        XCTAssertTrue(whole, "\(bench): line 20 not whole inside lobby_sheet_more after \(drags) drags: "
                      + (last.exists ? "at \(last.frame), the scroller at \(more.frame)" : "not in the tree"))
        XCTAssertEqual(app.id("lobby_sheet").frame, sheet, "\(bench): the sheet moved while its lines were scrolled")
        last.mustShow("Like Pocket Notebook · 20 of 20", "\(bench): the sheet's last line")
        report(bench, "More like this: sheet at \(Self.describe(sheet)), its scroller at \(Self.describe(scroller)); "
               + "line 20 \(lastAtOpen) at open, whole after \(drags) drag(s) inside the scroller")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "\(bench): More like this at line 20"
        shot.lifetime = .keepAlways
        add(shot)

        last.tapWhenThere()
        app.id("lobby_sheet").mustVanish("\(bench): a tap on a line did not close the sheet")
        // the long press, then the line: the drags touched nothing
        app.id("lobby_touch_log").mustContain("Tapped: Like Pocket Notebook · 20 of 20 (quick sheet, Pocket Notebook)", "\(bench): the line's tap; lobby_touch_log")
        app.id("lobby_touch_count").mustShow("Touches: 2", "\(bench): touches after the long press and the line; lobby_touch_count")
        XCTAssertEqual(app.id("lobby_top_row_position").label, topRow, "\(bench): the Top 10 row moved under the sheet")
        XCTAssertFalse(app.id("lobby_detail").exists, "\(bench): a line opened something")
    }

    static func describe(_ frame: CGRect) -> String {
        "\(Int(frame.minX)),\(Int(frame.minY)) \(Int(frame.width))×\(Int(frame.height))"
    }

    // MARK: WebDriverAgent's gesture

    struct Drag {
        let from: CGPoint
        let to: CGPoint
    }

    /// The drags WebDriverAgent 13.2.0 makes to scroll `frame` by `vector` (`fb_scrollByVector`): each at most 75 % of
    /// the frame on each axis, until what is left is within a point; a drag shorter than 20 points is not made
    /// (`FBFuzzyPointThreshold`). Each starts a quarter in from the frame's edge, or three quarters in on an axis the
    /// vector goes negative on (`fb_hitPointOffsetForScrollingVector`).
    static func wdaDrags(frame: CGRect, vector: CGVector) -> [Drag] {
        let bound = CGVector(dx: floor(copysign(frame.width * 0.75, vector.dx)), dy: floor(copysign(frame.height * 0.75, vector.dy)))
        var left = vector
        var drags: [Drag] = []
        for _ in 0..<20 {
            let step = CGVector(dx: abs(left.dx) > abs(bound.dx) ? bound.dx : left.dx, dy: abs(left.dy) > abs(bound.dy) ? bound.dy : left.dy)
            left = CGVector(dx: left.dx - step.dx, dy: left.dy - step.dy)
            let from = CGPoint(x: floor(frame.minX + frame.width * (step.dx < 0 ? 0.75 : 0.25)),
                               y: floor(frame.minY + frame.height * (step.dy < 0 ? 0.75 : 0.25)))
            let to = CGPoint(x: from.x + step.dx, y: from.y + step.dy)
            if hypot(to.x - from.x, to.y - from.y) >= 20 { drags.append(Drag(from: from, to: to)) }
            if abs(left.dx) <= 1 && abs(left.dy) <= 1 { break }
        }
        return drags
    }

    /// One drag as WebDriverAgent makes it: pressed for 0.5 s, dragged at 300 points a second, held for 0.5 s.
    static func perform(_ app: XCUIApplication, _ drag: Drag) {
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let begin = origin.withOffset(CGVector(dx: drag.from.x, dy: drag.from.y))
        let end = origin.withOffset(CGVector(dx: drag.to.x, dy: drag.to.y))
        begin.press(forDuration: 0.5, thenDragTo: end, withVelocity: XCUIGestureVelocity(300), thenHoldForDuration: 0.5)
    }

    // MARK: The tree

    struct Scroller {
        let type: XCUIElement.ElementType
        let identifier: String
        let frame: CGRect
    }

    /// Every element of a type WebDriverAgent scrolls in, depth first in child order: the order of Appium's page source.
    private func scrollers(_ app: XCUIApplication) -> [Scroller] {
        guard let root = try? app.snapshot() else { return [] }
        let types: Set<XCUIElement.ElementType> = [.scrollView, .collectionView, .table, .webView]
        var found: [Scroller] = []
        func walk(_ node: XCUIElementSnapshot) {
            if types.contains(node.elementType) { found.append(Scroller(type: node.elementType, identifier: node.identifier, frame: node.frame)) }
            node.children.forEach(walk)
        }
        walk(root)
        return found
    }

    private func expectOrder(_ bench: String, _ found: [Scroller], _ ids: [String], _ state: String) {
        let positions = ids.map { id in found.firstIndex { $0.identifier == id } }
        XCTAssertFalse(positions.contains(nil), "\(bench), \(state): not all of \(ids) are scrollers: \(describe(found))")
        let known = positions.compactMap { $0 }
        XCTAssertEqual(known, known.sorted(), "\(bench), \(state): not in the order \(ids): \(describe(found))")
    }

    private func describe(_ scroller: Scroller) -> String {
        let name = scroller.identifier.isEmpty ? "(no id)" : scroller.identifier
        return "\(name) [\(Self.typeName(scroller.type))] at \(Int(scroller.frame.minX)),\(Int(scroller.frame.minY)) "
            + "\(Int(scroller.frame.width))×\(Int(scroller.frame.height))"
    }

    private func describe(_ scrollers: [Scroller]) -> String { scrollers.map(describe).joined(separator: " → ") }

    static func typeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .scrollView: "XCUIElementTypeScrollView"
        case .collectionView: "XCUIElementTypeCollectionView"
        case .table: "XCUIElementTypeTable"
        case .webView: "XCUIElementTypeWebView"
        default: "type \(type.rawValue)"
        }
    }

    /// The deepest element with an identifier whose frame holds `point`: what the finger lands on.
    private func elementUnder(_ app: XCUIApplication, _ point: CGPoint) -> String {
        guard let root = try? app.snapshot() else { return "?" }
        var best: XCUIElementSnapshot?
        func walk(_ node: XCUIElementSnapshot) {
            if !node.identifier.isEmpty && node.frame.contains(point) { best = node }
            node.children.forEach(walk)
        }
        walk(root)
        guard let best else { return "nothing named at \(point)" }
        return "\(best.identifier) \"\(best.label)\" at \(Int(point.x)),\(Int(point.y))"
    }

    private func keepTree(_ app: XCUIApplication, _ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name
        tree.lifetime = .keepAlways
        add(tree)
    }

    private func report(_ bench: String, _ line: String) {
        let text = "LOBBY: \(bench == Self.swiftUI ? "SwiftUI" : "UIKit"): \(line)"
        print(text)
        XCTContext.runActivity(named: text) { _ in }
    }
}

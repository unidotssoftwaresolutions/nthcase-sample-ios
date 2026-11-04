import Foundation
import XCTest

/// What the first three CI runs taught, made certain here without a simulator: the text fields' focus rule, the tab
/// bar, the lists' ids, how the UI tests open a link, the UI tests' own lists (the walk's coverage, the ids the tests
/// name, the screenshots' names), and the workflow's shape, so the next run reports every check together.
final class CICensusTests: XCTestCase {
    private func lines(_ path: String) throws -> [String] { try Repo.text(path).components(separatedBy: "\n") }

    private func matches(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) throws -> [[String]] {
        let regex = try NSRegularExpression(pattern: pattern, options: options)
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
            (0..<match.numberOfRanges).map { i in Range(match.range(at: i), in: text).map { String(text[$0]) } ?? "" }
        }
    }

    /// Whether a concrete id ("shop_item_7") is an instance of a list entry ("shop_item_{id}"), as the UI tests decide.
    private func instance(_ concrete: String, of entry: String) -> Bool {
        guard entry.contains("{") else { return concrete == entry }
        let prefix = entry.prefix { $0 != "{" }
        let tail = concrete.dropFirst(prefix.count)
        return concrete.hasPrefix(prefix) && !tail.isEmpty && tail.allSatisfy { $0.isLetter || $0.isNumber }
    }

    private func nativeIds() throws -> [String] { try Repo.specIds().ids.map(\.id).filter { !$0.hasPrefix("web_") } }

    // MARK: Text fields

    /// Every text field is bound to its screen's @FocusState (a PasswordField to its screen's focus request), and
    /// sits in a box (FieldBox, or OutlinedField, which draws one) whose whole area focuses it. The first CI run
    /// stopped on a field a tap did not focus; a field that only takes the tap on its 22-point line of text is the
    /// defect a person and NthCase meet first.
    ///
    /// No SecureField: a password is one PasswordField whose dots come and go in place. The second CI run found the
    /// field that replaced a SecureField "not hittable" after Show password, and a SecureField that lost "garden42"
    /// when a new editing session began.
    func testEveryTextFieldIsFocusedFromItsWholeBox() throws {
        var fieldsByFile: [String: Int] = [:]
        for file in try Repo.appSwiftFiles() {
            let source = try lines("Mossgrove/\(file)")
            XCTAssertNil(source.joined().range(of: #"\bSecureField\("#, options: .regularExpression), "\(file): a SecureField; use PasswordField")
            for (index, line) in source.enumerated() where line.range(of: #"\b(TextField|PasswordField)\("#, options: .regularExpression) != nil {
                fieldsByFile[file, default: 0] += 1
                let after = source[index..<min(index + 12, source.count)].joined(separator: "\n")
                if line.contains("PasswordField(") {
                    let call = source[index..<min(index + 2, source.count)].joined(separator: "\n")
                    XCTAssertNotNil(call.range(of: #"focusRequest: \w+"#, options: .regularExpression), "\(file):\(index + 1): a password with no focus request")
                } else {
                    XCTAssertNotNil(after.range(of: ".focused($"), "\(file):\(index + 1): a text field with no .focused binding")
                }
                let before = source[max(0, index - 10)..<index]
                XCTAssertTrue(before.contains { ($0.contains("OutlinedField(") || $0.contains("FieldBox(")) && $0.contains("focus: {") },
                              "\(file):\(index + 1): a text field outside a box that focuses it")
            }
            XCTAssertNil(source.joined().range(of: "scrollDismissesKeyboard(.immediately)"),
                         "\(file): every screen lowers the keyboard the same way, .interactively")
        }
        XCTAssertEqual(fieldsByFile, ["Screens/SignInView.swift": 2, "Screens/ShopView.swift": 1, "Screens/FormView.swift": 2,
                                      "Screens/GiftCardsView.swift": 1])
        for (file, id) in [("SignInView", "signinPassword"), ("FormView", "formPassword")] {
            XCTAssertNotNil(try Repo.text("Mossgrove/Screens/\(file).swift").range(of: "id: TestIds.\(id), focusRequest: "), "\(id) is not a PasswordField")
        }
        // The field edits a hidden password through the rule LogicTests checks, and starts each session fresh.
        let component = try Repo.text("Mossgrove/Components/Components.swift")
        XCTAssertNotNil(component.range(of: "PasswordEditing.apply(to: field.text ?? \"\", range: range, replacement: string, sessionJustBegan: sessionJustBegan)"))
        XCTAssertNotNil(component.range(of: "func textFieldDidBeginEditing(_ field: UITextField) { fresh = true }"))
    }

    // MARK: The tab bar, the lists, the links

    /// The tab bar is the app's own: four SwiftUI buttons, each with its nav_* id, in the spec's order. No TabView and
    /// no UITabBarItem, whose identifier did not reach the tree on iOS 26 (second CI run). The UI tests find a tab by
    /// its id, never by the system bar.
    func testTheTabsAreTheAppsOwnButtons() throws {
        let tabs = try Repo.text("Mossgrove/App/MainTabs.swift")
        // the code, without its comments, which say why there is no TabView
        let code = tabs.components(separatedBy: "\n").map { $0.components(separatedBy: "//")[0] }.joined(separator: "\n")
        for system in ["TabView", "UITabBar", ".tabItem", "tabBarController"] {
            XCTAssertNil(code.range(of: system), "MainTabs uses \(system)")
        }
        let order = try matches(#"tab\(\.(\w+), icon: "\w+", id: TestIds\.(\w+)\)"#, in: tabs).map { [$0[1], $0[2]] }
        XCTAssertEqual(order, [["shop", "navShop"], ["cart", "navCart"], ["lab", "navLab"], ["settings", "navSettings"]])
        XCTAssertNotNil(tabs.range(of: "return Button { model.navigation.select(tab) } label: {"))
        XCTAssertNotNil(tabs.range(of: ".accessibilityIdentifier(id)\n"))
        XCTAssertNotNil(tabs.range(of: ".accessibilityLabel(tab == .cart ? cartTabLabel(count: count) : tab.title)"))
        for file in ["FlowTests", "IdWalkTests", "ScreenshotTests", "Support"] {
            XCTAssertNil(try Repo.text("MossgroveUITests/\(file).swift").range(of: "tabBars"), "\(file) looks for the system tab bar")
        }
        XCTAssertNotNil(try Repo.text("MossgroveUITests/IdWalkTests.swift").range(of: "func testEveryTabIsTheButtonAPersonTaps()"))
    }

    /// A list's id is on a container around its scroll view (`.scrollingList`), never on the ScrollView, one rule for
    /// all four lists; what decides whether it reaches the tree is the screen around it
    /// (testEveryScreenRootIsANodeOfItsOwn).
    func testEveryListIdIsOnAContainerAroundItsScrollView() throws {
        for (file, member) in [("ShopView", "shopList"), ("CartView", "cartList"), ("OrdersView", "ordersList"), ("SlowView", "slowContent")] {
            let source = try Repo.text("Mossgrove/Screens/\(file).swift")
            XCTAssertEqual(source.components(separatedBy: "TestIds.\(member)").count - 1, 1, "\(member) is used once")
            XCTAssertNotNil(source.range(of: "                }\n                .scrollingList(TestIds.\(member))")
                            ?? source.range(of: ".refreshable { await refresh() }\n                .scrollingList(TestIds.\(member))"),
                            "\(member) is not the ScrollView's .scrollingList")
        }
        XCTAssertNotNil(try Repo.text("Mossgrove/Components/Components.swift").range(of: "VStack(spacing: 0) { self }.container(id)"))
    }

    /// Every SwiftUI screen's root is `.screen(id)`, a node of its own: never `.container` alone, which SwiftUI folds
    /// into the screen's only child, so the screen took the list's node and `orders_list` and `slow_content` were in
    /// no tree (second and third CI runs). The shapes script that shows it uses the app's own helpers, copied.
    func testEveryScreenRootIsANodeOfItsOwn() throws {
        let screens = ["SignInView": "signinScreen", "ShopView": "shopScreen", "ItemView": "itemScreen", "CartView": "cartScreen",
                       "LabView": "labScreen", "FormView": "formScreen", "GesturesView": "gesturesScreen",
                       "CareGuideView": "webviewScreen", "SlowView": "slowScreen", "OrdersView": "ordersScreen"]
        for (file, member) in screens {
            let source = try Repo.text("Mossgrove/Screens/\(file).swift")
            XCTAssertEqual(source.components(separatedBy: ".screen(TestIds.\(member))").count - 1, 1, "\(file): its root is not .screen")
        }
        for file in try Repo.appSwiftFiles() {
            let source = try Repo.text("Mossgrove/\(file)")
            XCTAssertNil(source.range(of: #"\.container\(TestIds\.\w+Screen\)"#, options: .regularExpression), "\(file): a screen root that can fold")
        }
        let components = try Repo.text("Mossgrove/Components/Components.swift")
        let script = try Repo.text("scripts/ax-shapes.swift")
        let helpers = [
            "    func container(_ id: String) -> some View {\n        accessibilityElement(children: .contain).accessibilityIdentifier(id)\n    }",
            "    func scrollingList(_ id: String) -> some View {\n        VStack(spacing: 0) { self }.container(id)\n    }",
            "    func screen(_ id: String) -> some View {\n        ZStack {\n            ScreenAnchor()\n            self\n        }\n        .container(id)\n    }",
            "private struct ScreenAnchor: View {\n    var body: some View {\n        Color.clear\n            .frame(width: 0, height: 0)\n"
                + "            .allowsHitTesting(false)\n            .accessibilityHidden(true)\n    }\n}",
        ]
        for helper in helpers {
            XCTAssertNotNil(components.range(of: helper), "Components.swift: \(helper.prefix(40))")
            XCTAssertNotNil(script.range(of: helper), "scripts/ax-shapes.swift does not copy \(helper.prefix(40))")
        }
    }

    /// The banner sits above the Cart's checkout panel: the panel lifts it by its height while it is on screen. The
    /// third CI run's flow 03 tapped Check out under the Add-to-cart banner, and no dialog came.
    func testTheBannerSitsAboveCheckOut() throws {
        XCTAssertNotNil(try Repo.text("Mossgrove/Components/Snackbar.swift").range(of: ".padding(.bottom, 8 + model.snackbarLift)"))
        let cart = try Repo.text("Mossgrove/Screens/CartView.swift")
        let panel = try XCTUnwrap(cart.components(separatedBy: "private var checkoutPanel: some View {").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNotNil(panel.range(of: ".onGeometryChange(for: CGFloat.self) { $0.size.height } action: { model.snackbarLift = $0 }"))
        XCTAssertNotNil(panel.range(of: ".onDisappear { model.snackbarLift = 0 }"))
        let flows = try Repo.text("MossgroveUITests/FlowTests.swift")
        XCTAssertNotNil(flows.range(of: "func testTheBannerLeavesCheckOutFree()"))
        let flow03 = try XCTUnwrap(flows.components(separatedBy: "func test03CartAndOrder() {").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNotNil(flow03.range(of: "        checkOutIsFree()\n        app.id(\"cart_checkout\").tapWhenThere()\n        expect(\"dialog_title\""),
                        "flow 03 taps Check out without checking that it is free")
    }

    /// The budget is a UISlider (Appium and XCUITest read its scrubbers and value) whose 14.5-point thumb has its
    /// centre where XCUITest presses, 7.25 points inside each end of the track, and whose value follows the finger alone: UIKit's own
    /// tracking never runs. The fourth CI run read $130, $50, $100, $130 for 0.6, 0.3, 0.45, 0.6: the third run's
    /// accessibility-frame override changed nothing, as XCUITest reads no frame (SliderTrack).
    func testTheBudgetIsATravelSlider() throws {
        let form = try Repo.text("Mossgrove/Screens/FormView.swift")
        XCTAssertNil(form.range(of: #"\bSlider\("#, options: .regularExpression), "FormView uses SwiftUI's Slider")
        XCTAssertNotNil(form.range(of: "StepSlider(value: $budget, range: FormRules.budgetRange, step: FormRules.budgetStep, label: \"Monthly budget\",\n"
                                    + "                                   id: TestIds.formBudget)"))
        let components = try Repo.text("Mossgrove/Components/Components.swift")
        let slider = try XCTUnwrap(components.components(separatedBy: "final class TravelSlider: UISlider {").last?
            .components(separatedBy: "\n/// A full-width filled button").first)
        XCTAssertNil(slider.range(of: "accessibilityFrame"), "an accessibility frame XCUITest does not read")
        XCTAssertNil(slider.range(of: "override func trackRect("), "a track rect moves UIKit's scrubbers with it")
        XCTAssertNotNil(slider.range(of: "let size = CGSize(width: SliderTrack.xcuiThumbWidth, height: 28)"))
        XCTAssertNotNil(components.range(of: "slider.setThumbImage(thumb, for: .normal)\n        slider.setThumbImage(thumb, for: .highlighted)"))
        XCTAssertNotNil(slider.range(of: "let fraction = SliderTrack.fraction(fingerX: Double(x), grab: Double(grab), low: Double(travel.minX), high: Double(travel.maxX))"))
        for touch in ["touchesBegan", "touchesMoved", "touchesEnded", "touchesCancelled"] {
            let body = try XCTUnwrap(slider.components(separatedBy: "override func \(touch)(").last?.components(separatedBy: "\n        }\n").first)
            XCTAssertNil(body.range(of: "super."), "\(touch) hands the finger to UIKit's tracking")
        }
        XCTAssertNotNil(slider.range(of: "    override func addGestureRecognizer(_ recognizer: UIGestureRecognizer) {\n            recognizer.isEnabled = false"))
        XCTAssertNotNil(slider.range(of: "gestureRecognizers?.forEach { $0.isEnabled = false }"))
        XCTAssertNotNil(slider.range(of: "self.point(inside: point, with: event) ? self : nil"))
        XCTAssertNotNil(components.range(of: "let snapped = SliderTrack.snapped(Double(slider.value), range: parent.range, step: parent.step)"))
        XCTAssertNotNil(try Repo.text("MossgroveUITests/FlowTests.swift").range(of: "func testTheBudgetLandsWhereSlideSetsIt()"))
    }

    /// The form ends editing when a person moves on to a control that takes no typing, the newsletter row is one tap
    /// target that is a switch to Appium, and the club's password is not offered to Passwords. In the fourth CI run
    /// the password's keyboard lay over the switch through two taps, and "Save Password?" lay over the Lab after the
    /// filled form was left.
    func testTheFormLetsGoOfTheKeyboardAndAsksNoPasswordSave() throws {
        let form = try Repo.text("Mossgrove/Screens/FormView.swift")
        XCTAssertNotNil(form.range(of: "UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)"))
        for opener in ["                Button {\n                    endEditing()\n                    aisleOpen.toggle()",
                       "                    Button {\n                        endEditing()\n                        pickedDate = form.deliveryDate ?? Date()",
                       "        Button {\n            endEditing()\n            form.newsletter.toggle()",
                       "            Button {\n                endEditing()\n                form.acceptedTerms.toggle()",
                       "    private func join() {\n        endEditing()"] {
            XCTAssertNotNil(form.range(of: opener), "does not end editing: \(opener.split(separator: "\n").last ?? "")")
        }
        XCTAssertNotNil(form.range(of: ".accessibilityRepresentation { Toggle(\"Email me about new drawers\", isOn: $form.newsletter) }\n"
                                    + "        .accessibilityIdentifier(TestIds.formNewsletter)"))
        XCTAssertNotNil(form.range(of: "Toggle(\"\", isOn: $form.newsletter).labelsHidden().allowsHitTesting(false).accessibilityHidden(true)"))
        XCTAssertNil(form.range(of: "Toggle(isOn: $form.newsletter)"), "the newsletter is a Toggle whose label takes no tap")
        XCTAssertNil(form.range(of: ".newPassword"), "the club's password is offered to Passwords")
        XCTAssertNil(form.range(of: "contentType: .password"), "the club's password is offered to Passwords")
        XCTAssertNotNil(try Repo.text("Mossgrove/Components/Components.swift").range(of: "window?.endEditing(true)"))
    }

    /// The UI tests act as NthCase does: a tap finds its element first (`tapWhenThere`), Back waits until the screen
    /// it left is gone, the id walk keeps what it could not do and goes on, and keeps the tree when anything is
    /// missing. The focus check looks every quarter second. In the third CI run a tap right after Back from Gestures
    /// found no `lab_webview` and ended the walk, and a field that had the focus was failed for not having it.
    func testTheUITestsWaitAsNthCaseDoes() throws {
        for file in ["FlowTests", "IdWalkTests", "ScreenshotTests", "Support"] {
            let source = try Repo.text("MossgroveUITests/\(file).swift")
            XCTAssertEqual(try matches(#"\bid\("[a-z0-9_]+"\)\.tap\(\)|scrollTo\(app\.id\("[a-z0-9_]+"\)(, up: true)?\)\.tap\(\)"#, in: source).count, 0,
                           "\(file): a tap on an id that does not wait for it")
        }
        let support = try Repo.text("MossgroveUITests/Support.swift")
        XCTAssertNotNil(support.range(of: "guard button.tapWhenThere(file: file, line: line) else { return }\n        if !button.waitToVanish(timeout: 5) {"))
        XCTAssertNotNil(support.range(of: "guard waitForExistence(timeout: timeout) else {"))
        let focus = try XCTUnwrap(support.components(separatedBy: "private func focusAtEnd(").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNil(focus.range(of: "XCTNSPredicateExpectation"), "the focus is waited for by an expectation XCTest polls once a second")
        XCTAssertNotNil(focus.range(of: "if waitForFocus(until: tapped.addingTimeInterval(3)) { return true }"))
        let walk = try Repo.text("MossgroveUITests/IdWalkTests.swift")
        XCTAssertNotNil(walk.range(of: "        Misses.keep()\n        defer { Misses.stopKeeping() }"))
        XCTAssertNotNil(walk.range(of: "let couldNot = Misses.take()"))
        XCTAssertNotNil(walk.range(of: "let whole = XCTAttachment(string: app.debugDescription)"))
    }

    /// A tap that something covers is not made: the miss names the cover and the walk goes on (fourth CI run: XCUITest's
    /// own "not hittable" ended the walk with seven steps unchecked). iOS's "Save Password?" card is reported and
    /// answered wherever it comes up. A switch is set with one tap, never a second at a guessed point.
    func testTheUITestsNameWhatCoversATap() throws {
        let support = try Repo.text("MossgroveUITests/Support.swift")
        let tap = try XCTUnwrap(support.components(separatedBy: "func tapWhenThere(").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNotNil(tap.range(of: "app.answerSavePasswordCard(file: file, line: line)"))
        XCTAssertNotNil(tap.range(of: "if !isHittable && !waitForHittable(timeout: 3) {"))
        XCTAssertNotNil(tap.range(of: "covered by \\(cover)\",\n                              file: file, line: line)\n                return false"))
        let set = try XCTUnwrap(support.components(separatedBy: "    func set(_ on: Bool").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNil(set.range(of: "coordinate("), "a second tap at a guessed point")
        XCTAssertEqual(set.components(separatedBy: "tap()").count - 1, 1, "one tap")
        XCTAssertNotNil(set.range(of: "lies under the keyboard"))
        let back = try XCTUnwrap(support.components(separatedBy: "    func back(").last?.components(separatedBy: "\n    }\n").first)
        XCTAssertNotNil(back.range(of: "answerSavePasswordCard(within: 1.5, file: file, line: line)"))
        XCTAssertNotNil(support.range(of: "NSPredicate(format: \"label == %@\", \"Save Password?\")"))
        XCTAssertNotNil(try Repo.text("MossgroveUITests/IdWalkTests.swift").range(of: "step.act(app)\n                app.answerSavePasswordCard()"))
        let flows = try Repo.text("MossgroveUITests/FlowTests.swift")
        XCTAssertNotNil(flows.range(of: "XCTAssertTrue(app.keyboards.firstMatch.waitToVanish(timeout: 3), \"the keyboard stayed up after choosing an aisle\")"))
        XCTAssertNotNil(flows.range(of: "    override func setUp() {\n        continueAfterFailure = true"), "a flow stops at its first failed check")
    }

    /// A UI test hands a link to the running app the way the system does (Support's openLinkWhileRunning). Only
    /// openLinkFromColdStart may call XCUIApplication.open(_:), which relaunched the app in the second CI run.
    func testTheUITestsOpenLinksTheWayTheSystemDoes() throws {
        for file in ["FlowTests", "IdWalkTests", "ScreenshotTests"] {
            let source = try Repo.text("MossgroveUITests/\(file).swift")
            XCTAssertNil(source.range(of: ".open(URL("), "\(file) opens a link with XCUIApplication.open")
        }
        let support = try Repo.text("MossgroveUITests/Support.swift")
        XCTAssertEqual(support.components(separatedBy: "\n        open(URL(").count - 1, 1, "XCUIApplication.open is called once, from a cold start")
        XCTAssertNotNil(support.range(of: "        terminate()\n        open(URL(string: link)!)"))
        XCTAssertNotNil(support.range(of: "XCUIDevice.shared.system.open(URL(string: link)!)"))
        let flows = try Repo.text("MossgroveUITests/FlowTests.swift")
        XCTAssertNotNil(flows.range(of: "func test11DeepLinkWhileRunning()"))
        XCTAssertNotNil(flows.range(of: "func test11DeepLinkSignedOutWhileRunning()"))
    }

    // MARK: The UI tests' own lists

    /// The id walk names every native id of the list at least once, and nothing outside it. (IdWalkTests checks the
    /// same in CI; this makes it certain before a simulator starts.)
    func testTheWalkNamesEveryId() throws {
        let source = try Repo.text("MossgroveUITests/IdWalkTests.swift")
        let lists = try matches(#"ids: \[([^\]]*)\]"#, in: source).map { $0[1] }
        XCTAssertGreaterThan(lists.count, 30)
        let walked = try lists.flatMap { list in try matches(#""([a-z0-9_]+)""#, in: list).map { $0[1] } }
        let native = try nativeIds()
        XCTAssertEqual(native.filter { entry in !walked.contains { instance($0, of: entry) } }, [], "ids the walk never checks")
        XCTAssertEqual(walked.filter { id in !native.contains { instance(id, of: $0) } }, [], "ids the walk checks that are not in the list")
    }

    /// Every id-shaped string in the UI tests is an id of the list (a template by an instance), so no check in CI
    /// waits on a misspelt id.
    func testEveryIdTheUITestsNameIsInTheList() throws {
        let spec = try Repo.specIds()
        let prefixes = Set(spec.ids.map { String($0.id.prefix { $0 != "_" }) })
        let native = try nativeIds()
        let folder = Repo.url("MossgroveUITests")
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasSuffix(".swift") }.sorted()
        XCTAssertEqual(files, ["FlowTests.swift", "IdWalkTests.swift", "ScreenshotTests.swift", "Support.swift"])
        var named = 0
        for file in files {
            for match in try matches(#""(([a-z]+)_[a-z0-9_]+)""#, in: try Repo.text("MossgroveUITests/\(file)")) where prefixes.contains(match[2]) {
                named += 1
                XCTAssertTrue(native.contains { instance(match[1], of: $0) }, "\(file) names \(match[1]), which is not in the list")
            }
        }
        XCTAssertGreaterThan(named, 300)
    }

    /// The 24 screenshots: ScreenshotTests makes them under the names the CI script checks, one each, 01 to 24.
    func testTheScreenshotNamesAgree() throws {
        let tests = try matches(#"shot\("(\d\d-[a-z-]+)""#, in: try Repo.text("MossgroveUITests/ScreenshotTests.swift")).map { $0[1] }
        let script = try Repo.text("scripts/ci-screenshots.sh")
        let block = try XCTUnwrap(try matches(#"expected="([^"]*)""#, in: script).first?[1])
        let expected = block.split(whereSeparator: \.isWhitespace).map(String.init)
        XCTAssertEqual(tests.count, 24)
        XCTAssertEqual(Set(tests).count, 24, "a screenshot name twice")
        XCTAssertEqual(Set(tests), Set(expected))
        XCTAssertEqual(expected.count, 24)
        XCTAssertEqual(Set(expected.map { String($0.prefix(2)) }), Set((1...24).map { String(format: "%02d", $0) }))
    }

    // MARK: The workflows

    // AMENDED (CI diet, 2026-11-04): the job moved from build.yml into ci.yml, a reusable workflow that build.yml and
    // release.yml both call. build.yml runs only the fast checks on a push or a pull request, and asks for the device
    // suite on "Run workflow" and every Monday; release.yml always asks for it. The checks below read the job's steps
    // in ci.yml now, read all three files for pins, permissions and timeouts, and read build.yml and release.yml for
    // when each part runs. Nothing they checked before is checked less.
    private static let workflows = [".github/workflows/build.yml", ".github/workflows/ci.yml", ".github/workflows/release.yml"]

    /// The steps of the device suite: they run only when the caller asks for the suite.
    private static let deviceSteps = ["simulator", "build", "shots_light", "shots_dark", "unit", "walk", "flows", "tabs_older"]

    /// The files a push or a pull request may change without starting CI.
    private static let ignored = ["README.md", "CONTRIBUTING.md", "SECURITY.md", "LICENSE", "NOTICE", "docs/screenshots/**"]

    /// The test job's steps, as blocks of text, in order.
    private func buildSteps() throws -> [String] {
        let source = try Repo.text(".github/workflows/ci.yml") // AMENDED: the job was in build.yml
        let steps = try XCTUnwrap(source.components(separatedBy: "\n    steps:\n").last)
        return steps.components(separatedBy: "\n      - ").map { $0.hasPrefix("      - ") ? String($0.dropFirst(8)) : $0 }
    }

    /// The condition of one step, or "" when it has none.
    private func stepCondition(_ step: String) throws -> String {
        try matches(#"(?m)^        if: (.*)$|^if: (.*)$"#, in: step).first.map { $0[1] + $0[2] } ?? ""
    }

    /// Every action is pinned to a commit with its version beside it; the workflows read only, but the release job,
    /// and every job has a timeout.
    /// AMENDED: a job may also call this repository's own ci.yml by its path, which no one else can move; every step
    /// has a timeout of its own as well; and these three are the only workflows.
    func testTheWorkflowsArePinnedReadOnlyAndBounded() throws {
        for path in Self.workflows {
            let source = try Repo.text(path)
            let uses = try matches(#"(?m)^\s+(?:- )?uses: (\S+)(.*)$"#, in: source)
            XCTAssertFalse(uses.isEmpty, path)
            for use in uses {
                if use[1].hasPrefix("./") {
                    XCTAssertEqual(use[1], "./.github/workflows/ci.yml", "\(path): calls \(use[1])")
                    XCTAssertEqual(use[2], "", "\(path): \(use[1]) has something after it")
                    XCTAssertNotEqual(path, ".github/workflows/ci.yml", "ci.yml calls itself")
                    continue
                }
                XCTAssertNotNil(use[1].range(of: #"^[\w.-]+/[\w.-]+@[0-9a-f]{40}$"#, options: .regularExpression), "\(path): \(use[1]) is not a commit")
                XCTAssertNotNil(use[2].range(of: #"^ # v\d"#, options: .regularExpression), "\(path): \(use[1]) has no version beside it")
            }
            XCTAssertTrue(source.contains("\npermissions:\n  contents: read\n"), "\(path) reads only")
            let jobs = try matches(#"\n    runs-on: "#, in: source).count
            XCTAssertEqual(try matches(#"\n    timeout-minutes: \d+\n"#, in: source).count, jobs, "\(path): a job without a timeout")
            for block in source.components(separatedBy: "\n    steps:\n").dropFirst() {
                // the steps of one job end where the next job starts
                let end = block.range(of: #"\n  [^ \n]"#, options: .regularExpression)?.lowerBound ?? block.endIndex
                let job = "\n" + String(block[..<end])
                let steps = try matches(#"\n      - "#, in: job).count
                XCTAssertGreaterThan(steps, 0, path)
                XCTAssertEqual(try matches(#"\n        timeout-minutes: \d+\n"#, in: job).count, steps, "\(path): a step without a timeout")
            }
            XCTAssertNil(source.range(of: "continue-on-error"), "\(path): a check that cannot fail its job")
        }
        XCTAssertNil(try Repo.text(".github/workflows/build.yml").range(of: "contents: write"))
        XCTAssertNil(try Repo.text(".github/workflows/ci.yml").range(of: "contents: write"))
        XCTAssertEqual(try Repo.text(".github/workflows/release.yml").components(separatedBy: "contents: write").count - 1, 1)
        let files = try FileManager.default.contentsOfDirectory(atPath: Repo.url(".github/workflows").path).sorted()
        XCTAssertEqual(files, ["build.yml", "ci.yml", "release.yml"])
    }

    /// The first run stopped at its first failing check and proved nothing after it. Now every step after the first
    /// check runs whatever came before (`!cancelled()` or `always()`); each check is its own step with its own
    /// timeout; the uploads happen on failure too; and the last step lists every check.
    /// AMENDED: the device suite's steps, and the uploads of what only they make, run only when the caller asks for
    /// the suite (`inputs.devices`); MossgroveKit's tests and the zip run every time.
    func testEveryCheckRunsAndIsReported() throws {
        let steps = try buildSteps()
        let first = try XCTUnwrap(steps.firstIndex { $0.contains("swift test --package-path MossgroveKit") })
        for step in steps[(first + 1)...] {
            let condition = try stepCondition(step)
            XCTAssertTrue(condition.contains("!cancelled()") || condition.contains("always()"),
                          "a step an earlier failure would skip: \(step.prefix(60))")
        }
        let checks = ["ci-screenshots.sh \"$UDID\" light", "ci-screenshots.sh \"$UDID\" dark", "-only-testing:MossgroveTests ",
                      "-only-testing:MossgroveUITests/IdWalkTests ", "-only-testing:MossgroveUITests/FlowTests ",
                      "-only-testing:MossgroveUITests/IdWalkTests/testEveryTabIsTheButtonAPersonTaps ",
                      "scripts/ci-simulator.sh older", "scripts/package-simulator-app.sh"]
        for check in checks {
            let owners = steps.filter { $0.contains(check) }
            XCTAssertEqual(owners.count, 1, "\(check) is not one step of its own")
            XCTAssertNotNil(owners.first?.range(of: "timeout-minutes: "), "\(check) has no timeout of its own")
        }
        for upload in steps.filter({ $0.contains("actions/upload-artifact@") }) {
            XCTAssertFalse(upload.contains("failure()") || upload.contains("success()"), "an upload that depends on the outcome")
        }
        XCTAssertTrue(steps.contains { $0.contains("name: test-results") && $0.contains("path: build/results/") })
        let summary = try XCTUnwrap(steps.last)
        XCTAssertTrue(summary.contains("if: always()") && summary.contains("scripts/ci-test-summary.py"), "the last step is the summary")
        let ids = steps.compactMap { try? matches(#"(?m)^        id: (\w+)$"#, in: $0).first?[1] }
        XCTAssertEqual(ids, ["kit", "simulator", "build", "shots_light", "shots_dark", "unit", "walk", "flows", "tabs_older", "package"])
        for id in ids {
            XCTAssertTrue(summary.contains("${{ steps.\(id).outcome }}"), "the summary does not report \(id)")
        }
        for step in steps {
            let condition = try stepCondition(step)
            if let id = try matches(#"(?m)^        id: (\w+)$"#, in: step).first?[1] {
                XCTAssertEqual(condition.contains("inputs.devices && "), Self.deviceSteps.contains(id),
                               "\(id): the device suite's steps, and only they, wait for inputs.devices")
            }
        }
        for name in ["name: screenshots\n", "name: test-results\n"] {
            let upload = try XCTUnwrap(steps.first { $0.contains(name) })
            XCTAssertTrue(try stepCondition(upload).contains("inputs.devices && !cancelled()"), "\(name) is uploaded only with the suite")
        }
        let zip = try XCTUnwrap(steps.first { $0.contains("name: mossgrove-ios-simulator\n") })
        XCTAssertFalse(try stepCondition(zip).contains("inputs.devices"), "the zip is uploaded on every run")
        XCTAssertTrue(steps.contains { $0.contains("VERSION: ${{ inputs.version }}") && $0.contains("package-simulator-app.sh \"$VERSION\"") })
    }

    /// AMENDED (new with the CI diet): a push to main or a pull request runs the fast checks, unless it changed only
    /// text that no check reads; "Run workflow" and Monday 03:17 UTC add the device suite; a newer push cancels an
    /// older run, and nothing else is ever cancelled; a tag runs every check, the suite included, before it publishes.
    func testTheSuiteRunsWhenAskedWeeklyAndBeforeEveryRelease() throws {
        let build = try Repo.text(".github/workflows/build.yml")
        let ignoredBlock = "    paths-ignore:\n" + Self.ignored.map { "      - \($0)\n" }.joined()
        XCTAssertTrue(build.contains("\non:\n  push:\n    branches: [main]\n" + ignoredBlock + "  pull_request:\n"), "push to main, but for the text")
        XCTAssertTrue(build.contains("\n  pull_request:\n" + ignoredBlock + "  workflow_dispatch:\n"), "every pull request, but for the text")
        XCTAssertEqual(try matches(#"(?m)^\s+paths(?:-ignore)?:"#, in: build).count, 2, "one list for each, and no other filter")
        XCTAssertTrue(build.contains("\n  workflow_dispatch:\n"), "Run workflow")
        XCTAssertTrue(build.contains("\n  schedule:\n") && build.contains("\n    - cron: \"17 3 * * 1\"\n"), "Monday 03:17 UTC")
        XCTAssertTrue(build.contains("\nconcurrency:\n  group: build-${{ github.event_name }}-${{ github.ref }}\n"
                                     + "  cancel-in-progress: ${{ github.event_name == 'push' || github.event_name == 'pull_request' }}\n"))
        XCTAssertTrue(build.contains("\n  ci:\n    uses: ./.github/workflows/ci.yml\n    with:\n"
                                     + "      version: build-${{ github.run_number }}\n"
                                     + "      devices: ${{ github.event_name == 'workflow_dispatch' || github.event_name == 'schedule' }}\n"))

        // Nothing a test reads is in the list: SPEC.md, nthcase/ with its scenarios' .md files, art/, the app, the scripts.
        let folder = "MossgroveKit/Tests/MossgroveKitTests"
        var read: [String] = []
        for file in try FileManager.default.contentsOfDirectory(atPath: Repo.url(folder).path) where file.hasSuffix(".swift") {
            read += try matches(#"(?:text|data|url|lines)\("([^"\\]+)"#, in: try Repo.text("\(folder)/\(file)")).map { $0[1] }
        }
        XCTAssertTrue(read.contains("SPEC.md") && read.contains("nthcase/scenarios") && read.contains("art/"), "the reader of the tests")
        for path in read {
            for pattern in Self.ignored {
                let hit = pattern.hasSuffix("/**") ? path.hasPrefix(String(pattern.dropLast(2))) : path == pattern
                XCTAssertFalse(hit, "a test reads \(path), which a push could change without starting CI")
            }
        }

        let release = try Repo.text(".github/workflows/release.yml")
        XCTAssertTrue(release.contains("\non:\n  push:\n    tags:\n      - \"v*\"\n\n"), "a v* tag, and nothing else")
        XCTAssertNil(release.range(of: "\nconcurrency:"), "a release is never cancelled")
        XCTAssertNil(try Repo.text(".github/workflows/ci.yml").range(of: "\nconcurrency:"), "nor the suite a release runs")
        XCTAssertTrue(release.contains("\n  ci:\n    uses: ./.github/workflows/ci.yml\n    with:\n"
                                       + "      version: ${{ github.ref_name }}\n      devices: true\n"), "the release runs the suite")
        XCTAssertTrue(release.contains("\n  github-release:\n    needs: ci\n"), "and publishes only after every check")
        XCTAssertNil(release.range(of: "github-release:\n    needs: ci\n    if:"), "whatever the checks found")
        XCTAssertTrue(try Repo.text(".github/workflows/ci.yml").contains("\non:\n  workflow_call:\n"), "ci.yml runs only when called")
    }
}

import Foundation
import XCTest

/// What the first CI run taught, made certain here without a simulator: the text fields' focus rule, the UI tests'
/// own lists (the walk's coverage, the ids the tests name, the screenshots' names), and the workflow's shape, so the
/// next run reports every check together.
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

    /// Every text field is bound to its screen's @FocusState, and sits in a box (FieldBox, or OutlinedField, which
    /// draws one) whose whole area focuses it. The first CI run stopped on a field a tap did not focus; a field that
    /// only takes the tap on its 22-point line of text is the defect a person and NthCase meet first.
    func testEveryTextFieldIsFocusedFromItsWholeBox() throws {
        var fieldsByFile: [String: Int] = [:]
        for file in try Repo.appSwiftFiles() {
            let source = try lines("Mossgrove/\(file)")
            for (index, line) in source.enumerated() where line.range(of: #"\b(TextField|SecureField)\("#, options: .regularExpression) != nil {
                fieldsByFile[file, default: 0] += 1
                let after = source[index..<min(index + 12, source.count)].joined(separator: "\n")
                XCTAssertNotNil(after.range(of: ".focused($"), "\(file):\(index + 1): a text field with no .focused binding")
                let before = source[max(0, index - 10)..<index]
                XCTAssertTrue(before.contains { ($0.contains("OutlinedField(") || $0.contains("FieldBox(")) && $0.contains("focus: {") },
                              "\(file):\(index + 1): a text field outside a box that focuses it")
            }
            XCTAssertNil(source.joined().range(of: "scrollDismissesKeyboard(.immediately)"),
                         "\(file): every screen lowers the keyboard the same way, .interactively")
        }
        XCTAssertEqual(fieldsByFile, ["Screens/SignInView.swift": 3, "Screens/ShopView.swift": 1, "Screens/FormView.swift": 3,
                                      "Screens/GiftCardsView.swift": 1])
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

    /// The test job's steps, as blocks of text, in order.
    private func buildSteps() throws -> [String] {
        let source = try Repo.text(".github/workflows/build.yml")
        let steps = try XCTUnwrap(source.components(separatedBy: "\n    steps:\n").last)
        return steps.components(separatedBy: "\n      - ").map { $0.hasPrefix("      - ") ? String($0.dropFirst(8)) : $0 }
    }

    /// Every action is pinned to a commit with its version beside it; the workflows read only, but the release job,
    /// and every job has a timeout.
    func testTheWorkflowsArePinnedReadOnlyAndBounded() throws {
        for path in [".github/workflows/build.yml", ".github/workflows/release.yml"] {
            let source = try Repo.text(path)
            let uses = try matches(#"(?m)^\s+(?:- )?uses: (\S+)(.*)$"#, in: source)
            XCTAssertFalse(uses.isEmpty, path)
            for use in uses {
                XCTAssertNotNil(use[1].range(of: #"^[\w.-]+/[\w.-]+@[0-9a-f]{40}$"#, options: .regularExpression), "\(path): \(use[1]) is not a commit")
                XCTAssertNotNil(use[2].range(of: #"^ # v\d"#, options: .regularExpression), "\(path): \(use[1]) has no version beside it")
            }
            XCTAssertTrue(source.contains("\npermissions:\n  contents: read\n"), "\(path) reads only")
            let jobs = try matches(#"\n    runs-on: "#, in: source).count
            XCTAssertEqual(try matches(#"\n    timeout-minutes: \d+\n"#, in: source).count, jobs, "\(path): a job without a timeout")
            XCTAssertNil(source.range(of: "continue-on-error"), "\(path): a check that cannot fail its job")
        }
        XCTAssertNil(try Repo.text(".github/workflows/build.yml").range(of: "contents: write"))
        XCTAssertEqual(try Repo.text(".github/workflows/release.yml").components(separatedBy: "contents: write").count - 1, 1)
    }

    /// The first run stopped at its first failing check and proved nothing after it. Now every step after the first
    /// check runs whatever came before (`!cancelled()` or `always()`); each check is its own step with its own
    /// timeout; the uploads happen on failure too; and the last step lists every check.
    func testEveryCheckRunsAndIsReported() throws {
        let steps = try buildSteps()
        let first = try XCTUnwrap(steps.firstIndex { $0.contains("swift test --package-path MossgroveKit") })
        for step in steps[(first + 1)...] {
            let condition = try matches(#"(?m)^        if: (.*)$|^if: (.*)$"#, in: step).first.map { $0[1] + $0[2] } ?? ""
            XCTAssertTrue(condition.contains("!cancelled()") || condition.contains("always()"),
                          "a step an earlier failure would skip: \(step.prefix(60))")
        }
        let checks = ["ci-screenshots.sh \"$UDID\" light", "ci-screenshots.sh \"$UDID\" dark", "-only-testing:MossgroveTests ",
                      "-only-testing:MossgroveUITests/IdWalkTests ", "-only-testing:MossgroveUITests/FlowTests ",
                      "scripts/package-simulator-app.sh"]
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
        XCTAssertEqual(ids, ["kit", "simulator", "build", "shots_light", "shots_dark", "unit", "walk", "flows", "package"])
        for id in ids {
            XCTAssertTrue(summary.contains("${{ steps.\(id).outcome }}"), "the summary does not report \(id)")
        }
    }
}

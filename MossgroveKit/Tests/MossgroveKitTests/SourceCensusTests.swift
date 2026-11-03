import Foundation
import XCTest

/// The repository, read as files: the spec's lists against the app's source. Runs on a Mac with `swift test`.
enum Repo {
    /// …/MossgroveKit/Tests/MossgroveKitTests/SourceCensusTests.swift → the repository root.
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    static func url(_ path: String) -> URL { root.appendingPathComponent(path) }

    static func text(_ path: String) throws -> String { try String(contentsOf: url(path), encoding: .utf8) }

    static func data(_ path: String) throws -> Data { try Data(contentsOf: url(path)) }

    /// Every Swift file of the app (not its tests), as a path relative to `Mossgrove/`.
    static func appSwiftFiles() throws -> [String] {
        let base = url("Mossgrove")
        let walker = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)!
        var files: [String] = []
        for case let file as URL in walker where file.pathExtension == "swift" {
            files.append(String(file.standardizedFileURL.path.dropFirst(base.standardizedFileURL.path.count + 1)))
        }
        return files.sorted()
    }

    struct SpecId: Decodable {
        let id: String
        let screen: String
    }

    struct SpecIds: Decodable {
        let spec: String
        let pattern: String
        let ids: [SpecId]
    }

    static func specIds() throws -> SpecIds { try JSONDecoder().decode(SpecIds.self, from: data("nthcase/test-ids.json")) }
}

final class SourceCensusTests: XCTestCase {
    /// Where each id must be used, by its JSON screen (and, for the chrome, by its prefix). Paths are under
    /// `Mossgrove/`.
    private func expectedFile(for id: Repo.SpecId) -> String {
        switch id.screen {
        case "chrome":
            if id.id.hasPrefix("nav_") { return "App/MainTabs.swift" }
            if id.id.hasPrefix("top_bar_") { return "Components/TopBar.swift" }
            if id.id.hasPrefix("snackbar") { return "Components/Snackbar.swift" }
            if id.id.hasPrefix("dialog") { return "Components/Dialog.swift" }
            return "?"
        case "signin": return "Screens/SignInView.swift"
        case "shop": return "Screens/ShopView.swift"
        case "item": return "Screens/ItemView.swift"
        case "cart": return "Screens/CartView.swift"
        case "lab": return "Screens/LabView.swift"
        case "form": return "Screens/FormView.swift"
        case "gestures": return "Screens/GesturesView.swift"
        case "webview": return "Screens/CareGuideView.swift"
        case "slow": return "Screens/SlowView.swift"
        case "orders": return "Screens/OrdersView.swift"
        case "settings": return "Settings/SettingsViewController.swift"
        default: return "?"
        }
    }

    /// TestIds.swift, read as text: member name → id ("shop_item_{id}" for a function).
    private func testIdsSource() throws -> [String: String] {
        let source = try Repo.text("MossgroveKit/Sources/MossgroveKit/TestIds.swift")
        var members: [String: String] = [:]
        let constant = try NSRegularExpression(pattern: #"static let (\w+) = "([a-z0-9_]+)""#)
        let template = try NSRegularExpression(pattern: #"static func (\w+)\(_ (\w+): \w+\) -> String \{ "([a-z0-9_]+)_\\\((\w+)\)" \}"#)
        let range = NSRange(source.startIndex..., in: source)
        func group(_ match: NSTextCheckingResult, _ i: Int) -> String { String(source[Range(match.range(at: i), in: source)!]) }
        for match in constant.matches(in: source, range: range) {
            XCTAssertNil(members[group(match, 1)], "\(group(match, 1)) is declared twice")
            members[group(match, 1)] = group(match, 2)
        }
        for match in template.matches(in: source, range: range) {
            XCTAssertEqual(group(match, 2), group(match, 4), "\(group(match, 1)): the parameter is the template's name")
            members[group(match, 1)] = "\(group(match, 3))_{\(group(match, 2))}"
        }
        return members
    }

    /// TestIds.swift declares exactly the JSON's native ids: none missing, none extra, none twice.
    func testTestIdsAreExactlyTheJsonList() throws {
        let spec = try Repo.specIds()
        XCTAssertEqual(spec.spec, "1.0")
        let native = spec.ids.map(\.id).filter { !$0.hasPrefix("web_") }
        XCTAssertEqual(native.count, Set(native).count, "the JSON lists an id twice")
        let declared = try testIdsSource()
        XCTAssertEqual(declared.count, Set(declared.values).count, "TestIds.swift declares an id twice")
        XCTAssertEqual(Set(declared.values), Set(native))
        XCTAssertEqual(declared.count, 138)
        XCTAssertEqual(spec.ids.count, 147)
        let pattern = try NSRegularExpression(pattern: spec.pattern)
        for id in spec.ids.map(\.id) {
            let bare = id.replacingOccurrences(of: #"_\{\w+\}"#, with: "_1", options: .regularExpression)
            XCTAssertNotNil(pattern.firstMatch(in: bare, range: NSRange(bare.startIndex..., in: bare)), "\(id) breaks the id pattern")
        }
    }

    /// Every id is used on its own screen's file, and in no other file of the app.
    func testEveryIdIsUsedExactlyWhereExpected() throws {
        let spec = try Repo.specIds()
        let declared = try testIdsSource()
        let memberById = Dictionary(uniqueKeysWithValues: declared.map { ($0.value, $0.key) })
        let files = try Repo.appSwiftFiles()
        XCTAssertGreaterThan(files.count, 15)
        let sources = try Dictionary(uniqueKeysWithValues: files.map { ($0, try Repo.text("Mossgrove/\($0)")) })
        for id in spec.ids where !id.id.hasPrefix("web_") {
            let member = try XCTUnwrap(memberById[id.id], id.id)
            let use = try NSRegularExpression(pattern: #"\bTestIds\.\#(member)\b"#)
            let usedIn = Set(sources.filter { use.firstMatch(in: $0.value, range: NSRange($0.value.startIndex..., in: $0.value)) != nil }.keys)
            XCTAssertEqual(usedIn, [expectedFile(for: id)], "\(id.id) (TestIds.\(member))")
        }
    }

    /// No id is written as a string in the app: every identifier comes from TestIds, so none can be outside the list.
    func testNoIdOutsideTheList() throws {
        let spec = try Repo.specIds()
        let prefixes = Set(spec.ids.map { String($0.id.prefix { $0 != "_" }) }).union(["top"])
        let literal = try NSRegularExpression(pattern: #""(([a-z]+)_[a-z0-9_]*)"#)
        for file in try Repo.appSwiftFiles() {
            let source = try Repo.text("Mossgrove/\(file)")
            for match in literal.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                let word = String(source[Range(match.range(at: 2), in: source)!])
                let text = String(source[Range(match.range(at: 1), in: source)!])
                XCTAssertFalse(prefixes.contains(word), "\(file) writes the id-shaped string \"\(text)\": use TestIds")
            }
            XCTAssertNil(source.range(of: #"accessibilityIdentifier\s*(=|\()\s*""#, options: .regularExpression), "\(file) sets an identifier from a string literal")
        }
    }

    /// Gift cards has no ids at all, by design: no identifier and no TestIds in its file.
    func testGiftCardsHasNoIds() throws {
        let source = try Repo.text("Mossgrove/Screens/GiftCardsView.swift")
        XCTAssertNil(source.range(of: "accessibilityIdentifier"))
        XCTAssertNil(source.range(of: "TestIds"))
        XCTAssertNotNil(source.range(of: "tagged: false"), "its top bar is the untagged one")
    }

    /// The page's ids: every `web_*` id is on the bundled page as both `id` and `data-testid`, and nothing else is.
    func testWebIdsAreOnTheBundledPage() throws {
        let page = try Repo.text("Mossgrove/Resources/care-guide.html")
        let web = Set(try Repo.specIds().ids.map(\.id).filter { $0.hasPrefix("web_") })
        XCTAssertEqual(web.count, 9)
        let pair = try NSRegularExpression(pattern: #"id="([a-z_]+)" data-testid="([a-z_]+)""#)
        var found: Set<String> = []
        for match in pair.matches(in: page, range: NSRange(page.startIndex..., in: page)) {
            let id = String(page[Range(match.range(at: 1), in: page)!])
            XCTAssertEqual(id, String(page[Range(match.range(at: 2), in: page)!]))
            found.insert(id)
        }
        XCTAssertEqual(found, web)
        XCTAssertEqual(page.components(separatedBy: " id=\"").count - 1, web.count, "an id without its data-testid")
    }
}

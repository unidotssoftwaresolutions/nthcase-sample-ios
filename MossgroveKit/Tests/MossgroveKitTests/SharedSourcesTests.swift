import Foundation
import XCTest
@testable import MossgroveKit

/// The shared sources (SPEC.md, the ids, the scenarios, the art, the page) against the app built from them.
final class SharedSourcesTests: XCTestCase {
    /// SPEC.md §3's table is the catalogue, word for word.
    func testCatalogueIsSpecTable() throws {
        let spec = try Repo.text("SPEC.md")
        XCTAssertTrue(spec.hasPrefix("# Mossgrove: the NthCase sample apps (spec 1.0)"))
        let rows = spec.split(separator: "\n").filter { $0.range(of: #"^\| 0[0-4]\d \|"#, options: .regularExpression) != nil }
        XCTAssertEqual(rows.count, 40)
        for (row, item) in zip(rows, Catalog.items) {
            let cells = row.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            XCTAssertEqual(cells[0], String(format: "%03d", item.id))
            XCTAssertEqual(cells[1], item.name)
            XCTAssertEqual(cells[2], "\(item.aisle.label) (`\(item.aisle.key)`)")
            XCTAssertEqual(cells[3], item.glyph.rawValue)
            XCTAssertEqual(cells[4], item.price)
            XCTAssertEqual(cells[5], item.description)
        }
    }

    /// The five slots, the spec's §5 texts the app quotes, and the scenarios are all in SPEC.md as written.
    func testFixedTextsAreTheSpecs() throws {
        // SPEC.md wraps its lines, so a text may run across a line break there
        let spec = try Repo.text("SPEC.md").replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        for text in Texts.slots + [
            Texts.signInMissing, Texts.signInWrong, Texts.searchPlaceholder, Texts.refreshed, Texts.shopLoading,
            Texts.shopFailed, Texts.noMatchHelp, Texts.addedToCart, Texts.backToShop, Texts.cartEmpty, Texts.cartEmptyHelp,
            Texts.placeThisOrder, Texts.labIntro, Texts.formIntro, Texts.joined, Texts.pageLoading, Texts.pageLoaded,
            Texts.slotsLoading, Texts.slotsIntro, Texts.ordersLoading, Texts.ordersFailed, Texts.ordersFailedHelp,
            Texts.noOrders, Texts.noOrdersHelp, Texts.giftUnknown, Texts.notificationsNotAllowed, Texts.notificationsOn,
            Texts.testingHelp, Texts.slowLoading, Texts.failFirstLoad, Texts.resetTitle, Texts.resetBody, Texts.resetDone,
            Texts.notificationSent, Texts.testNotificationTitle, Texts.version("1.0.0"),
            FormRules.name, FormRules.email, FormRules.age, FormRules.password, FormRules.category, FormRules.date, FormRules.terms,
            GestureWords.doubleTapped, GestureWords.dropped, GestureWords.dropMissed, GestureWords.scrolledTo,
        ] {
            XCTAssertNotNil(spec.range(of: text), "SPEC.md does not say \"\(text)\"")
        }
        let scenarios = try FileManager.default.contentsOfDirectory(atPath: Repo.url("nthcase/scenarios").path).sorted()
        XCTAssertEqual(scenarios.count, 12)
        XCTAssertEqual(scenarios.first, "01-sign-in.md")
        XCTAssertEqual(scenarios.last, "README.md")
    }

    /// The asset catalog's drawings are the `art/` files, byte for byte (scripts/make-assets.swift copies them).
    func testAssetCatalogCarriesTheArtUnchanged() throws {
        var count = 0
        for folder in ["icons", "glyphs"] {
            let names = try FileManager.default.contentsOfDirectory(atPath: Repo.url("art/\(folder)").path).filter { $0.hasSuffix(".svg") }
            for name in names {
                let asset = (folder == "icons" ? "icon-" : "glyph-") + name.dropLast(4).replacingOccurrences(of: "_", with: "-")
                let copy = "Mossgrove/Resources/Assets.xcassets/\(asset).imageset/\(asset).svg"
                XCTAssertEqual(try Repo.data(copy), try Repo.data("art/\(folder)/\(name)"), copy)
                let contents = try Repo.text("Mossgrove/Resources/Assets.xcassets/\(asset).imageset/Contents.json")
                XCTAssertNotNil(contents.range(of: "\"preserves-vector-representation\" : true"), asset)
                XCTAssertNotNil(contents.range(of: "\"template-rendering-intent\" : \"template\""), asset)
                count += 1
            }
        }
        XCTAssertEqual(count, 27)
        XCTAssertEqual(Set(Glyph.allCases.map(\.rawValue)),
                       Set(try FileManager.default.contentsOfDirectory(atPath: Repo.url("art/glyphs").path).map { String($0.dropLast(4)) }))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Repo.url("Mossgrove/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png").path))
    }

    /// The page loads nothing remote: its policy forbids it, and it names no URL but its own anchor.
    func testThePageLoadsNothing() throws {
        let page = try Repo.text("Mossgrove/Resources/care-guide.html")
        XCTAssertNotNil(page.range(of: "default-src 'none'"))
        XCTAssertNil(page.range(of: "http://"))
        XCTAssertNil(page.range(of: "https://"))
    }
}

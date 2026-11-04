// SwiftUI's own accessibility tree for the shapes Mossgrove's screens have, read on this Mac with no simulator.
//
//   swiftc -O scripts/ax-shapes.swift -o build/ax-shapes && build/ax-shapes
//
// It hosts each shape in an off-screen window, reads the tree SwiftUI builds for it, prints it, and checks which ids
// are in it. Exits 1 if a shape that the app uses loses an id. A Mac, not a simulator: this is macOS SwiftUI's tree,
// built by the same accessibility modifiers as on iOS; XCUITest's tree on iOS is proven in CI by the id walk.
//
// What it shows (third CI round):
// - "folded": a screen container whose only child is a list container (Orders with one order, Delivery slots) is ONE
//   node, and it carries the screen's id. The list's id is gone. That is `orders_list` and `slow_content`.
// - The same with a sibling (Shop's search, the Cart's checkout panel) keeps both ids. That is why `shop_list` and
//   `cart_list` were found.
// - `.screen(id)`, the app's screen root, keeps both ids on every shape the app has.
//
// The three helpers below are the app's own (Mossgrove/Components/Components.swift), copied; CICensusTests checks
// that the copies match.
import AppKit
import SwiftUI

extension View {
    func container(_ id: String) -> some View {
        accessibilityElement(children: .contain).accessibilityIdentifier(id)
    }

    func scrollingList(_ id: String) -> some View {
        VStack(spacing: 0) { self }.container(id)
    }

    func screen(_ id: String) -> some View {
        ZStack {
            ScreenAnchor()
            self
        }
        .container(id)
    }
}

private struct ScreenAnchor: View {
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct Rows: View {
    var body: some View {
        VStack { ForEach(1...2, id: \.self) { Text("Row \($0)").accessibilityIdentifier("row_\($0)") } }
    }
}

struct Shape {
    let name: String
    let expected: [String]
    /// false: the shape the app had, shown for the record; its missing ids are expected
    let usedByTheApp: Bool
    let view: AnyView
}

let shapes: [Shape] = [
    Shape(name: "folded: screen container around nothing but a list container (Orders, Delivery slots before)",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: false,
          view: AnyView(ZStack { ScrollView { Rows() }.scrollingList("the_list") }.container("the_screen"))),
    Shape(name: "folded: the list id on the ScrollView itself (second CI run's Orders)",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: false,
          view: AnyView(ZStack { ScrollView { Rows() }.accessibilityIdentifier("the_list") }.container("the_screen"))),
    Shape(name: "kept: the list beside a header (Shop before)",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: false,
          view: AnyView(VStack { Text("Header"); ScrollView { Rows() }.scrollingList("the_list") }.container("the_screen"))),
    Shape(name: ".screen: nothing but a list (Orders, Delivery slots)",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: true,
          view: AnyView(ZStack { ScrollView { Rows() }.scrollingList("the_list") }.screen("the_screen"))),
    Shape(name: ".screen: nothing but a list, in a NavigationStack",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: true,
          view: AnyView(NavigationStack { ZStack { ScrollView { Rows() }.scrollingList("the_list") }.screen("the_screen") })),
    Shape(name: ".screen: a list beside a header (Shop)",
          expected: ["the_screen", "the_list", "row_1"], usedByTheApp: true,
          view: AnyView(VStack { Text("Header"); ScrollView { Rows() }.scrollingList("the_list") }.screen("the_screen"))),
    Shape(name: ".screen: a scroll view with no id of its own (Lab, Join the club)",
          expected: ["the_screen", "row_1"], usedByTheApp: true,
          view: AnyView(ScrollView { Rows() }.screen("the_screen"))),
    Shape(name: ".screen: one combined element (a spinner)",
          expected: ["the_screen", "the_loading"], usedByTheApp: true,
          view: AnyView(ZStack { VStack { Text("Loading") }.accessibilityElement(children: .combine).accessibilityIdentifier("the_loading") }
              .screen("the_screen"))),
    Shape(name: ".screen: a message and its button (an empty state)",
          expected: ["the_screen", "the_empty", "the_action"], usedByTheApp: true,
          view: AnyView(ZStack { VStack { Text("Nothing").accessibilityIdentifier("the_empty"); Button("Go") {}.accessibilityIdentifier("the_action") } }
              .screen("the_screen"))),
]

func tree(_ element: Any, depth: Int, lines: inout [String], ids: inout [String]) {
    guard depth < 16 else { return }
    let node = element as AnyObject
    let id: String = (node.accessibilityIdentifier?() ?? nil) ?? ""
    let role: String = (node.accessibilityRole?() ?? nil)?.rawValue ?? "?"
    if !id.isEmpty { ids.append(id) }
    lines.append(String(repeating: "  ", count: depth) + role + (id.isEmpty ? "" : " \"\(id)\""))
    let children: [Any] = (node.accessibilityChildren?() ?? nil) ?? []
    for child in children { tree(child, depth: depth + 1, lines: &lines, ids: &ids) }
}

let app = NSApplication.shared
// an accessory app: SwiftUI builds no accessibility tree for an app that may not have windows (.prohibited)
app.setActivationPolicy(.accessory)
// SwiftUI builds a window's accessibility tree only while an assistive client has asked for it (VoiceOver, an
// inspector, a UI-test runner). These are the two flags such a client sets on an app, set here on this process's own
// app only: nothing outside this process changes, and no permission is needed. Without them the tree comes and goes
// with whatever else runs on the Mac.
for flag in ["AXEnhancedUserInterface", "AXManualAccessibility"] {
    app.accessibilitySetValue(true, forAttribute: NSAccessibility.Attribute(rawValue: flag))
}
let windows: [NSWindow] = shapes.map { shape in
    let window = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 320, height: 320), styleMask: [.borderless],
                          backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: shape.view.frame(width: 320, height: 320))
    window.orderFrontRegardless()
    return window
}

/// Reads every shape's tree, every half second until one is there (up to 8 s): SwiftUI builds it after a layout.
func read(attempt: Int) {
    var results: [(Shape, [String], [String])] = []
    for (shape, window) in zip(shapes, windows) {
        var lines: [String] = []
        var ids: [String] = []
        tree(window.contentView!, depth: 0, lines: &lines, ids: &ids)
        results.append((shape, lines, ids))
    }
    if results.allSatisfy({ $0.2.isEmpty }) {
        if attempt < 16 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { read(attempt: attempt + 1) }
            return
        }
        print("NO TREE: SwiftUI built no accessibility tree for any shape within 8 s, so nothing was measured")
        exit(2)
    }
    var failures = 0
    for (shape, lines, ids) in results {
        let missing = shape.expected.filter { !ids.contains($0) }
        let verdict = missing.isEmpty ? "every id" : "missing \(missing.joined(separator: " "))"
        print("== \(shape.name): \(verdict)")
        lines.forEach { print("   " + $0) }
        if shape.usedByTheApp && !missing.isEmpty { failures += 1 }
    }
    print(failures == 0 ? "OK: every shape the app uses keeps every id" : "FAILED: \(failures) shape(s) the app uses lose an id")
    exit(failures == 0 ? 0 : 1)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { read(attempt: 0) }
app.run()

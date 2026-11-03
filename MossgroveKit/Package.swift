// swift-tools-version: 5.10
// MossgroveKit: the app's logic, with no UI. The catalogue, the cart, the form's rules, deep-link parsing, the gesture
// and shake rules, navigation, and the test-id list. It builds for iOS (the app) and macOS, so `swift test` runs it
// on a Mac with no simulator.
import PackageDescription

let package = Package(
    name: "MossgroveKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Dynamic, so the app and its hosted unit tests share one copy instead of each linking their own.
        .library(name: "MossgroveKit", type: .dynamic, targets: ["MossgroveKit"]),
    ],
    targets: [
        .target(name: "MossgroveKit"),
        .testTarget(name: "MossgroveKitTests", dependencies: ["MossgroveKit"]),
    ]
)

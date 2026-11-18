# Screenshots

Every screen, light and dark, as `light/NN-name.png` and `dark/NN-name.png`, with the same 31 names as the Android
app's (25–31 are the Lobby, new in spec 1.1; "views" is the UIKit Lobby). `MossgroveUITests/ScreenshotTests.swift` takes them on the CI simulator, never on a developer's machine. They
arrive as the `screenshots` artifact of the `build` workflow: unzip it at the repository root, and commit the two
folders.

# Screenshots

Every screen, light and dark, as `light/NN-name.png` and `dark/NN-name.png`, with the same 24 names as the Android
app's. `MossgroveUITests/ScreenshotTests.swift` takes them on the CI simulator, never on a developer's machine. They
arrive as the `screenshots` artifact of the `build` workflow: unzip it at the repository root, and commit the two
folders.

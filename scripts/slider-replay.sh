#!/bin/bash
# Builds and runs scripts/slider-replay.swift (see its header) as a Mac Catalyst app in build/slider-replay/.
# Exit 0: every slide lands. Exit 1: a slide missed (printed). Needs Xcode; boots no simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
out=build/slider-replay
mkdir -p "$out/src" "$out/SliderReplay.app/Contents/MacOS"
# the app's TravelSlider, cut from its source, with the two names it uses from elsewhere in the app
python3 - <<'PY'
src = open("Mossgrove/Components/Components.swift").read()
start = src.index("    final class TravelSlider: UISlider {")
end = src.index("\n/// A full-width filled button")
cls = src[start:end].rstrip()
cls = cls[:cls.rstrip().rfind("}")]                       # StepSlider's closing brace
cls = "\n".join(l[4:] if l.startswith("    ") else l for l in cls.split("\n"))
kit = open("MossgroveKit/Sources/MossgroveKit/SliderTrack.swift").read().replace("public ", "")
stubs = "enum FormRules { static let budgetStep = 10.0 }\nenum Palette { static let primary = UIColor.systemGreen }\n"
open("build/slider-replay/src/app-slider.swift", "w").write("// cut from the app by slider-replay.sh\nimport UIKit\n" + stubs + kit + "\n" + cls + "\n")
PY
cp scripts/slider-replay.swift "$out/src/main.swift"
cat > "$out/SliderReplay.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>test.mossgrove.slider-replay</string>
<key>CFBundleExecutable</key><string>SliderReplay</string>
<key>CFBundleName</key><string>SliderReplay</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>2</integer></array>
</dict></plist>
PLIST
sdk=$(xcrun --sdk macosx --show-sdk-path)
xcrun swiftc -target "$(uname -m)-apple-ios26.0-macabi" -sdk "$sdk" -Fsystem "$sdk/System/iOSSupport/System/Library/Frameworks" \
  "$out/src/app-slider.swift" "$out/src/main.swift" -o "$out/SliderReplay.app/Contents/MacOS/SliderReplay"
codesign -s - --force "$out/SliderReplay.app" >/dev/null 2>&1
exec "$out/SliderReplay.app/Contents/MacOS/SliderReplay"

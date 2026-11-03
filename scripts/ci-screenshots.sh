#!/usr/bin/env bash
# Takes every screen in one theme on the CI simulator, as docs/screenshots/<theme>/NN-name.png under <out>.
#
#   scripts/ci-screenshots.sh <udid> <light|dark> <out>
#
# The theme is the simulator's own appearance, so the app follows the system as it does by default. Needs a
# `build-for-testing` in build/DerivedData first. CI only.
set -euo pipefail
udid="${1:?usage: scripts/ci-screenshots.sh <udid> <light|dark> <out>}"
theme="${2:?light or dark}"
out="${3:?an output folder}"
cd "$(dirname "$0")/.."

folder="$out/docs/screenshots/$theme"
mkdir -p "$folder"
xcrun simctl ui "$udid" appearance "$theme"

# xcodebuild hands TEST_RUNNER_-prefixed variables to the test runner, without the prefix.
TEST_RUNNER_MOSSGROVE_SCREENSHOTS="$(cd "$folder" && pwd)" xcodebuild test-without-building \
  -project Mossgrove.xcodeproj -scheme Mossgrove -destination "id=$udid" -derivedDataPath build/DerivedData \
  -only-testing:MossgroveUITests/ScreenshotTests -resultBundlePath "build/results/screenshots-$theme.xcresult"

count=$(find "$folder" -name '*.png' | wc -l | tr -d ' ')
echo "$count screenshots in $folder"
test "$count" -eq 24

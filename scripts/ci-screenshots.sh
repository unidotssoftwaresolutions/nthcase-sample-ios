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

# xcodebuild hands TEST_RUNNER_-prefixed variables to the test runner, without the prefix. The tests' failures are
# read after the pictures are counted, so a red run still says which pictures it made.
status=0
TEST_RUNNER_MOSSGROVE_SCREENSHOTS="$(cd "$folder" && pwd)" xcodebuild test-without-building \
  -project Mossgrove.xcodeproj -scheme Mossgrove -destination "id=$udid" -derivedDataPath build/DerivedData \
  -only-testing:MossgroveUITests/ScreenshotTests -resultBundlePath "build/results/screenshots-$theme.xcresult" || status=$?

# The 24 screens, by the names ScreenshotTests gives them (SourceCensusTests checks that the two lists agree).
expected="01-sign-in 02-sign-in-error 03-shop 04-shop-search 05-shop-no-match 06-item 07-item-snackbar 08-cart
09-cart-dialog 10-cart-empty 11-lab 12-form-errors 13-form-done 14-gestures 15-webview 16-slow-loading 17-slow-done
18-orders 19-orders-empty 20-orders-error 21-gift-cards 22-settings 23-settings-dialog 24-deep-link-unknown"
missing=()
for name in $expected; do
  [[ -f "$folder/$name.png" ]] || missing+=("$name")
done
made=$(find "$folder" -name '*.png' | wc -l | tr -d ' ')
echo "$theme: $made of 24 screenshots in $folder"
if (( ${#missing[@]} > 0 )); then
  echo "::error title=Screenshots, $theme::${#missing[@]} of 24 not made: ${missing[*]}"
  status=1
fi
exit "$status"

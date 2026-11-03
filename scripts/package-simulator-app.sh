#!/usr/bin/env bash
# Builds Mossgrove.app for the iOS Simulator (Release, arm64 and x86_64), zips it, and checks the zip.
#
#   scripts/package-simulator-app.sh <tag>     →  dist/mossgrove-ios-<tag>-simulator.zip and dist/SHA256SUMS
#
# The zip installs on any iOS 17 or later simulator with `xcrun simctl install <udid> Mossgrove.app` after unzipping.
# A simulator app needs no signing certificate, so there is no .ipa and no secret anywhere.
set -euo pipefail
tag="${1:?usage: scripts/package-simulator-app.sh <tag>}"
cd "$(dirname "$0")/.."
root=$(pwd)

xcodebuild build -project Mossgrove.xcodeproj -scheme Mossgrove -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData \
  ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64" -jobs "${JOBS:-4}" -quiet

app=build/DerivedData/Build/Products/Release-iphonesimulator/Mossgrove.app
for binary in "$app/Mossgrove" "$app/Frameworks/MossgroveKit.framework/MossgroveKit"; do
  archs=$(lipo -archs "$binary")
  echo "$binary: $archs"
  [[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]] || { echo "not built for arm64 and x86_64" >&2; exit 1; }
done

zip="mossgrove-ios-${tag}-simulator.zip"
mkdir -p dist
rm -f "dist/$zip" dist/SHA256SUMS
(cd "$(dirname "$app")" && ditto -c -k --sequesterRsrc --keepParent Mossgrove.app "$root/dist/$zip")
(cd dist && shasum -a 256 "$zip" > SHA256SUMS)

# Read the Info.plist back out of the zip, not out of the build folder.
check=build/zip-check
rm -rf "$check"
mkdir -p "$check"
ditto -x -k "dist/$zip" "$check"
plist="$check/Mossgrove.app/Info.plist"
bundle=$(plutil -extract CFBundleIdentifier raw "$plist")
minimum=$(plutil -extract MinimumOSVersion raw "$plist")
scheme=$(plutil -extract CFBundleURLTypes.0.CFBundleURLSchemes.0 raw "$plist")
name=$(plutil -extract CFBundleDisplayName raw "$plist")
version=$(plutil -extract CFBundleShortVersionString raw "$plist")
platform=$(plutil -extract CFBundleSupportedPlatforms.0 raw "$plist")
echo "In the zip: $bundle, $name $version, minimum iOS $minimum, URL scheme $scheme, platform $platform"
[[ "$bundle" == "com.nthcase.sample" && "$minimum" == "17.0" && "$scheme" == "nthcase-sample" && "$platform" == "iPhoneSimulator" ]] \
  || { echo "the zip's Info.plist is not what the spec says" >&2; exit 1; }
rm -rf "$check"

size=$(stat -f%z "dist/$zip")
echo "dist/$zip: $size bytes"
cat dist/SHA256SUMS

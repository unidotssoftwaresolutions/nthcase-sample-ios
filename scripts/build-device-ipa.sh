#!/usr/bin/env bash
# Builds Mossgrove for a real iPhone (Release, arm64), signed ad hoc, as dist/mossgrove-ios-device.ipa, and writes its
# SHA-256 to dist/mossgrove-ios-device.ipa.sha256.
#
#   scripts/build-device-ipa.sh
#
# The .ipa is made to be re-signed by a device farm for the phone it runs on, so it carries no team, no certificate and
# no provisioning profile: Xcode builds it with code signing off, and this script signs the framework and then the app
# ad hoc (`codesign -s -`), with no entitlements. Ad hoc, not unsigned, because a re-signer reads the app's current
# entitlements with `codesign -d --entitlements` first, and an unsigned bundle has none to read: it is refused, not
# re-signed. It does not install on a phone as it is; a phone needs a signature from a team whose profile names it.
#
# Nothing here reads or needs a signing identity, a team or a profile, and nothing about the simulator build changes:
# this build has its own folder, build/DerivedData-device, and its own file in dist/ (dist/SHA256SUMS is the simulator
# zip's and is not touched). On a Mac with Xcode only.
set -euo pipefail
cd "$(dirname "$0")/.."
root=$(pwd)

derived=build/DerivedData-device
xcodebuild build -project Mossgrove.xcodeproj -scheme Mossgrove -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$derived" \
  ONLY_ACTIVE_ARCH=NO ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" \
  -jobs "${JOBS:-4}" -quiet

built="$derived/Build/Products/Release-iphoneos/Mossgrove.app"
[[ -d "$built" ]] || { echo "no app at $built" >&2; exit 1; }

# The app is copied before it is signed, so the build folder keeps what Xcode made.
stage=build/device-ipa
rm -rf "$stage"
mkdir -p "$stage/Payload"
ditto "$built" "$stage/Payload/Mossgrove.app"
app="$stage/Payload/Mossgrove.app"

# One app, one framework, no app extension, no link: what a re-signer signs one by one, and refuses otherwise.
nested=$(find "$app" -mindepth 1 \( -name '*.app' -o -name '*.appex' \) | wc -l | tr -d ' ')
links=$(find "$app" -type l | wc -l | tr -d ' ')
[[ "$nested" == 0 ]] || { echo "the app holds $nested nested app bundles; a re-signer refuses them" >&2; exit 1; }
[[ "$links" == 0 ]] || { echo "the app holds $links links; a re-signer refuses them" >&2; exit 1; }
[[ ! -e "$app/embedded.mobileprovision" ]] || { echo "the app carries a provisioning profile; it should carry none" >&2; exit 1; }

for binary in "$app/Mossgrove" "$app/Frameworks/MossgroveKit.framework/MossgroveKit"; do
  archs=$(lipo -archs "$binary")
  echo "$binary: $archs"
  [[ "$archs" == "arm64" ]] || { echo "not built for arm64 alone" >&2; exit 1; }
done

# Innermost first: a bundle's signature covers what is inside it.
codesign --force --sign - --timestamp=none "$app/Frameworks/MossgroveKit.framework"
codesign --force --sign - --timestamp=none "$app"
codesign --verify --strict --verbose=2 "$app"
entitlements=$(codesign -d --entitlements :- "$app" 2>/dev/null)
[[ -z "$entitlements" ]] || { echo "the ad hoc signature claims entitlements; it should claim none" >&2; exit 1; }

plist="$app/Info.plist"
bundle=$(plutil -extract CFBundleIdentifier raw "$plist")
minimum=$(plutil -extract MinimumOSVersion raw "$plist")
version=$(plutil -extract CFBundleShortVersionString raw "$plist")
buildno=$(plutil -extract CFBundleVersion raw "$plist")
platform=$(plutil -extract CFBundleSupportedPlatforms.0 raw "$plist")
sdk=$(plutil -extract DTPlatformName raw "$plist")
echo "In the app: $bundle $version ($buildno), minimum iOS $minimum, platform $platform, SDK $sdk"
[[ "$bundle" == "com.nthcase.sample" && "$minimum" == "17.0" && "$platform" == "iPhoneOS" && "$sdk" == "iphoneos" ]] \
  || { echo "the app's Info.plist is not a phone build of com.nthcase.sample for iOS 17" >&2; exit 1; }

# Payload/Mossgrove.app at the top of the archive, nothing else, no extended attributes.
ipa=mossgrove-ios-device.ipa
mkdir -p dist
rm -f "dist/$ipa" "dist/$ipa.sha256"
(cd "$stage" && zip -q -r -X "$root/dist/$ipa" Payload)
(cd dist && shasum -a 256 "$ipa" > "$ipa.sha256")

# Read back out of the archive, not out of the stage.
tops=$(zipinfo -1 "dist/$ipa" | cut -d/ -f1 | sort -u | tr '\n' ' ')
[[ "$tops" == "Payload " ]] || { echo "the archive's top level is '$tops', not Payload" >&2; exit 1; }
check=build/device-ipa-check
rm -rf "$check"
mkdir -p "$check"
(cd "$check" && unzip -q "$root/dist/$ipa")
codesign --verify --strict "$check/Payload/Mossgrove.app"
[[ $(plutil -extract CFBundleIdentifier raw "$check/Payload/Mossgrove.app/Info.plist") == "$bundle" ]] \
  || { echo "the archive's app is not the app that was signed" >&2; exit 1; }
rm -rf "$check" "$stage"

size=$(stat -f%z "dist/$ipa")
echo "dist/$ipa: $size bytes"
cat "dist/$ipa.sha256"

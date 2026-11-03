#!/usr/bin/env bash
# Creates a fresh iPhone simulator for one CI run, boots it, and prints its UDID.
#
#   udid=$(scripts/ci-simulator.sh)
#
# Every later step names the simulator by this UDID, never by `booted`, which means every booted simulator on the
# machine. CI only: do not run it on a Mac that has simulators of its own at work.
set -euo pipefail

pick=$(xcrun simctl list runtimes --json | python3 -c '
import json, sys
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and (r.get("platform") == "iOS" or r.get("name", "").startswith("iOS "))]
if not runtimes:
    sys.exit("no iOS simulator runtime is installed")
runtimes.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
runtime = runtimes[-1]
phones = [d for d in runtime.get("supportedDeviceTypes", []) if d.get("productFamily") == "iPhone" or d["name"].startswith("iPhone")]
if not phones:
    sys.exit("the newest iOS runtime lists no iPhone")
preferred = ["iPhone 17", "iPhone 16", "iPhone 17 Pro", "iPhone 16 Pro"]
phone = next((d for name in preferred for d in phones if d["name"] == name), phones[-1])
print(runtime["identifier"], phone["identifier"], runtime["name"], "/", phone["name"])
')
read -r runtime devicetype label <<<"$pick"
echo "Simulator: $label" >&2

udid=$(xcrun simctl create "Mossgrove CI" "$devicetype" "$runtime")
# No hardware keyboard, before the first boot: typing goes through the on-screen keyboard, as on a phone and as on
# NthCase's simulators (Appium's XCUITest driver leaves the hardware keyboard off unless asked). The Simulator reads
# this per device, and the global key covers a Simulator that ignores the per-device one.
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
defaults write com.apple.iphonesimulator DevicePreferences -dict-add "$udid" \
  '<dict><key>ConnectHardwareKeyboard</key><false/></dict>'
xcrun simctl bootstatus "$udid" -b >&2
# The same status bar in every screenshot.
xcrun simctl status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >&2
echo "$udid"

#!/usr/bin/env bash
# Creates a fresh iPhone simulator for one CI run, boots it, and prints its UDID.
#
#   udid=$(scripts/ci-simulator.sh)          the newest iOS runtime
#   udid=$(scripts/ci-simulator.sh older)    the oldest iOS runtime from 17.0 on that is not the newest; prints
#                                            nothing (and succeeds) when the runner has no such runtime
#
# Every later step names the simulator by this UDID, never by `booted`, which means every booted simulator on the
# machine. CI only: do not run it on a Mac that has simulators of its own at work.
set -euo pipefail
which="${1:-newest}"

pick=$(xcrun simctl list runtimes --json | python3 -c '
import json, sys
which = sys.argv[1]
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and (r.get("platform") == "iOS" or r.get("name", "").startswith("iOS "))]
if not runtimes:
    sys.exit("no iOS simulator runtime is installed")
runtimes.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
if which == "older":
    newest = runtimes[-1]["version"].split(".")[0]
    older = [r for r in runtimes if int(r["version"].split(".")[0]) >= 17 and r["version"].split(".")[0] != newest]
    if not older:
        sys.exit(0)
    runtime = older[0]
else:
    runtime = runtimes[-1]
phones = [d for d in runtime.get("supportedDeviceTypes", []) if d.get("productFamily") == "iPhone" or d["name"].startswith("iPhone")]
if not phones:
    sys.exit("the newest iOS runtime lists no iPhone")
preferred = ["iPhone 17", "iPhone 16", "iPhone 17 Pro", "iPhone 16 Pro"]
phone = next((d for name in preferred for d in phones if d["name"] == name), phones[-1])
print(runtime["identifier"], phone["identifier"], runtime["name"], "/", phone["name"])
' "$which")
if [[ -z "$pick" ]]; then
  echo "Simulator: no iOS runtime from 17.0 on older than the newest" >&2
  exit 0
fi
read -r runtime devicetype label <<<"$pick"
echo "Simulator: $label" >&2

udid=$(xcrun simctl create "Mossgrove CI ($which)" "$devicetype" "$runtime")
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

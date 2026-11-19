#!/usr/bin/env bash
# Unpacks what the build job built for testing (build/for-testing.tar, the for-testing artifact) into
# build/DerivedData/Build/Products, and names its .xctestrun for the job's later steps as $XCTESTRUN:
#
#   scripts/ci-unpack-for-testing.sh
#
# Each check job runs `xcodebuild test-without-building -xctestrun "$XCTESTRUN"` with it: no check builds the app.
# CI only.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/DerivedData/Build
tar -C build/DerivedData/Build -xf build/for-testing.tar
runs=(build/DerivedData/Build/Products/*.xctestrun)
if (( ${#runs[@]} != 1 )) || [[ ! -f "${runs[0]}" ]]; then
  echo "the build should hold one .xctestrun; it holds: ${runs[*]}" >&2
  exit 1
fi
echo "XCTESTRUN=$(pwd)/${runs[0]}" >> "$GITHUB_ENV"
echo "XCTESTRUN=$(pwd)/${runs[0]}"

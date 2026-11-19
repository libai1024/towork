#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
platform="$1"
device="$2"
out="build/mobile-verification/$platform"
mkdir -p "$out"
git rev-parse HEAD > "$out/source.txt"
if ! flutter test --no-pub --reporter expanded -d "$device" integration_test/free_workspace_ui_test.dart >"$out/ui.log" 2>&1; then
  cat "$out/ui.log"
  if [[ "$platform" == android ]]; then
    adb -s "$device" exec-out screencap -p > "$out/ui-failure.png"
    adb -s "$device" logcat -d -t 2000 flutter:I AndroidRuntime:E '*:S' > "$out/ui-host.log"
  else
    xcrun simctl io "$device" screenshot "$out/ui-failure.png"
  fi
  exit 1
fi
python3 tool/mobile_workspace_smoke.py "$platform" "$device" --artifacts "$out" 2>&1 | tee "$out/process.log"

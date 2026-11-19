#!/usr/bin/env bash
# Run only on an isolated iOS simulator. The fixture resets this bundle's model grants.
set -euo pipefail
cd "$(dirname "$0")/.."
device="$1"
out="${2:-build/mobile-verification/ios/consent}"
mkdir -p "$out"
axe="${AXE_BIN:-}"
if [[ -z "$axe" ]]; then
  cache=$(mktemp -d "${TMPDIR:-/tmp}/towork-axe.XXXXXX")
  curl --retry 2 -fsSL https://github.com/cameroncooke/AXe/releases/download/v2.0.4/AXe-macOS-v2.0.4-universal.tar.gz -o "$cache/archive.tar.gz"
  (cd "$cache" && echo '3178ec66d9ff46455fec737debad719c41cab16edb1435b2c721e07760a208c3  archive.tar.gz' | shasum -a 256 -c - && tar -xzf archive.tar.gz)
  axe="$cache/axe"
fi
xcrun simctl getenv "$device" SIMULATOR_UDID >/dev/null
diagnose() {
  "$axe" describe-ui --udid "$device" > "$out/failure-tree.json" || true
  xcrun simctl io "$device" screenshot "$out/failure.png" || true
  xcrun simctl spawn "$device" log show --last 3m --predicate 'process == "Runner"' > "$out/host.log" || true
}
trap diagnose ERR
flutter build ios --simulator --debug --no-pub --target integration_test/fixtures/ios_model_consent.dart
xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
xcrun simctl terminate "$device" com.towork.towork >/dev/null 2>&1 || true
xcrun simctl launch "$device" com.towork.towork
tap() { "$axe" tap --udid "$device" --label "$1" --wait-timeout 20 --post-delay 0.5; }
# iOS may expose Flutter semantics while the launch transition still intercepts touches.
# The first operation is idempotent while its native prompt is pending.
tap '验证 1'
sleep 1
"$axe" describe-ui --udid "$device" > "$out/first-step.json"
if ! grep -q '暂不允许' "$out/first-step.json"; then tap '验证 1'; fi
tap '允许'
tap '验证 2'
tap '验证 3'
tap '暂不允许'
tap '验证 4'
tap '允许'
tap '验证 5'
tap '验证 6'
tap '暂不允许'
tap '验证 7'
# Wait for the last native prompt before sending the scene into the background.
for attempt in {1..40}; do
  "$axe" describe-ui --udid "$device" > "$out/last-prompt.json"
  if grep -q '暂不允许' "$out/last-prompt.json"; then break; fi
  sleep 0.25
done
grep -q '暂不允许' "$out/last-prompt.json"
"$axe" button home --udid "$device"
sleep 1
xcrun simctl launch "$device" com.towork.towork
for attempt in {1..40}; do
  "$axe" describe-ui --udid "$device" > "$out/result-tree.json"
  if grep -q '通过 3' "$out/result-tree.json"; then break; fi
  sleep 0.25
done
grep -q '通过 3' "$out/result-tree.json"
echo 'Two origins, cache, denial, reset and background dismissal passed with three permitted HTTP requests.'

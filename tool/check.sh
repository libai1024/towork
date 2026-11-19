#!/usr/bin/env bash
# Keep local and CI quality checks identical. Run from any directory.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter_bin="${FLUTTER_BIN:-flutter}"
dart_bin="${DART_BIN:-dart}"

python3 tool/check_delivery.py
python3 tool/check_upgrade_docs.py
"$flutter_bin" pub get --enforce-lockfile
DART_BIN="$dart_bin" python3 tool/check_patch_assets.py
"$dart_bin" format --output=none --set-exit-if-changed lib test integration_test test_driver
"$flutter_bin" analyze --no-pub --fatal-infos
"$flutter_bin" test --no-pub test/architecture
"$flutter_bin" test --no-pub --coverage

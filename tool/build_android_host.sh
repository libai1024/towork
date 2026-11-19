#!/usr/bin/env bash
# Build the signed code-update host using the same SDK as its later patches.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter_executable="${FLUTTER_BIN:-$(command -v flutter)}"
patch_sdk="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().parent.parent)' "$flutter_executable")"
version="$(python3 tool/check_release_version.py)"
output="build/code-hosts/$version-$(date +%Y%m%d-%H%M%S)"
"$patch_sdk/bin/dart" run flutter_patcher build android --flutter-sdk "$patch_sdk" --out "$output"
python3 tool/verify_code_host.py "$output/app-release.apk"
mkdir -p build/app/outputs/flutter-apk
cp "$output/app-release.apk" build/app/outputs/flutter-apk/app-release.apk
backup="$HOME/.flutter_patcher/backups/towork"
mkdir -p "$backup"
chmod 700 "$backup"
rsync -a .flutter_patcher/baselines/ "$backup/baselines/"
echo "基础包与编译记录保存在 $output"

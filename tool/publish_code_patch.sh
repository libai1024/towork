#!/usr/bin/env bash
# Keep pubspec's host version. Compile against its archived baseline, then sign.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter_executable="${FLUTTER_BIN:-$(command -v flutter)}"
patch_sdk="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().parent.parent)' "$flutter_executable")"
if [[ "${1:-}" == "--withdraw" ]]; then
  withdraw_args=(--withdraw --yes)
  [[ -z "${2:-}" ]] || withdraw_args+=(--patch "$2")
  "$patch_sdk/bin/dart" run flutter_patcher publish "${withdraw_args[@]}"
else
  output="build/code-patches/$(python3 tool/check_release_version.py)-$(date +%Y%m%d-%H%M%S)"
  patch_cli="$(python3 tool/prepare_patch_cli.py)"
  "$patch_sdk/bin/dart" --packages="$patch_cli/package_config.json" "$patch_cli/flutter_patcher/bin/flutter_patcher.dart" patch android --flutter-sdk "$patch_sdk" --out "$output"
  "$patch_sdk/bin/dart" run flutter_patcher publish --patch "$output" --yes
fi
source tool/_server_ssh.sh
python3 tool/publish_code_objects.py --store .flutter_patcher/updates --host "$TOWORK_HOST" --download-dir "${TOWORK_DOWNLOAD_DIR:?Set the download directory}" --ssh-command "$SSH_CMD"
backup="$HOME/.flutter_patcher/backups/towork"
mkdir -p "$backup"
chmod 700 "$backup"
rsync -a .flutter_patcher/updates/ "$backup/updates/"

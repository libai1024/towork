#!/usr/bin/env bash
# 构建并发布 Android APK 到 https://zhaozhaoyue.top/dl/towork/ ，同时更新 latest.json。
#
# 用法：
#   tool/publish_android.sh "更新说明1" "更新说明2" ...     构建 + 上传 + 更新清单
#   TOWORK_SKIP_BUILD=1 tool/publish_android.sh ...         复用已有 build/app/outputs/flutter-apk/app-release.apk
#   TOWORK_DRY_RUN=1 tool/publish_android.sh ...            只构建并生成清单，不上传
#
# 约定（docs/release/README.md、docs/update/APP-UPDATE-DESIGN.md §3）：
# - 只出 arm64-v8a 单 ABI 包，versionCode 即 pubspec.yaml 的 build number（不做 split-per-abi 偏移）
# - 产物文件名含版本，服务器上视为不可变：同名文件哈希不同则拒绝覆盖
# - 先传产物，最后原子替换 latest.json（写 .tmp 再 mv）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DL_ROOT="${TOWORK_DOWNLOAD_DIR:-}"
PUBLIC_BASE="https://zhaozhaoyue.top/dl/towork"
APK="build/app/outputs/flutter-apk/app-release.apk"

version_line="$(python3 tool/check_release_version.py)"
VERSION_NAME="${version_line%%+*}"
VERSION_CODE="${version_line##*+}"
[[ "$VERSION_CODE" =~ ^[0-9]+$ ]] || { echo "pubspec.yaml version 缺少 +buildNumber：$version_line" >&2; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  echo "警告：工作区有未提交改动，发布包将包含它们。" >&2
fi
GIT_REV="$(git rev-parse --short HEAD)"

if [[ "${TOWORK_SKIP_BUILD:-0}" != "1" ]]; then
  bash tool/fetch_asr_models.sh
  bash tool/build_android_host.sh
fi
[[ -f "$APK" ]] || { echo "找不到 $APK" >&2; exit 1; }
python3 tool/verify_code_host.py "$APK"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
APKSIGNER="$(ls -d "$SDK"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1)"
[[ -x "$APKSIGNER" ]] || { echo "找不到 apksigner（$SDK/build-tools）" >&2; exit 1; }
python3 tool/verify_android_artifact.py "$(dirname "$APKSIGNER")/aapt" "$APK"
"$APKSIGNER" verify "$APK"
CERT_SHA256="$("$APKSIGNER" verify --print-certs "$APK" | awk -F': ' '/certificate SHA-256 digest/{print $2; exit}')"
CERT_DN="$("$APKSIGNER" verify --print-certs "$APK" | awk -F': ' '/certificate DN/{print $2; exit}')"
if [[ "$CERT_DN" == *"Android Debug"* ]]; then
  echo "注意：APK 使用 Android 调试证书签名（${CERT_DN}）。换正式 keystore 后，已安装用户需要卸载重装。" >&2
fi

FILE="towork-${VERSION_NAME}-${VERSION_CODE}-arm64.apk"
SHA256="$(shasum -a 256 "$APK" | awk '{print $1}')"
SIZE="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).stat().st_size)' "$APK")"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/android"
cp "$APK" "$STAGE/android/$FILE"

VERSION_NAME="$VERSION_NAME" VERSION_CODE="$VERSION_CODE" GIT_REV="$GIT_REV" FILE="$FILE" \
SHA256="$SHA256" SIZE="$SIZE" CERT_SHA256="$CERT_SHA256" \
python3 - "$STAGE/latest.json" "$@" <<'PY'
import datetime, json, os, sys
e = os.environ
manifest = {
    "schema": 1,
    "channel": "stable",
    "publishedAt": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "versionName": e["VERSION_NAME"],
    "versionCode": int(e["VERSION_CODE"]),
    "minSupportedVersionCode": 1,
    "rolloutPercent": 100,
    "gitRev": e["GIT_REV"],
    "releaseNotes": sys.argv[2:],
    "android": {
        "abi": "arm64-v8a",
        "certSha256": e["CERT_SHA256"],
        "full": {"url": "android/" + e["FILE"], "sha256": e["SHA256"], "size": int(e["SIZE"])},
        "patches": [],
    },
    "macos": {"downloadUrl": None, "appcastUrl": None},
    "ios": {"storeUrl": None},
}
with open(sys.argv[1], "w") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
PY

python3 tool/generate_android_patches.py "$STAGE"

echo "版本 $VERSION_NAME ($VERSION_CODE) $GIT_REV $FILE $((SIZE / 1024 / 1024)) MB"
echo "sha256 $SHA256"
echo "cert   $CERT_SHA256"

if [[ "${TOWORK_DRY_RUN:-0}" == "1" ]]; then
  cp "$STAGE/latest.json" build/latest.json
  RELEASE_DIR="build/releases/$version_line"
  mkdir -p "$RELEASE_DIR/android"
  cp "$STAGE/latest.json" "$RELEASE_DIR/latest.json"
  cp "$STAGE/android/$FILE" "$RELEASE_DIR/android/$FILE"
  for patch_file in "$STAGE"/android/*.hpatch; do
    [[ -f "$patch_file" ]] || continue
    cp "$patch_file" "$RELEASE_DIR/android/"
  done
  printf '%s  %s\n' "$SHA256" "android/$FILE" > "$RELEASE_DIR/SHA256SUMS"
  for patch_file in "$RELEASE_DIR"/android/*.hpatch; do
    [[ -f "$patch_file" ]] || continue
    printf '%s  android/%s\n' "$(shasum -a 256 "$patch_file" | awk '{print $1}')" "$(basename "$patch_file")" >> "$RELEASE_DIR/SHA256SUMS"
  done
  echo "DRY RUN：产物写到 ${RELEASE_DIR}，清单副本为 build/latest.json。"
  exit 0
fi

source "$ROOT/tool/_server_ssh.sh"
towork_check_path "$DL_ROOT" towork-dl
remote_sha="$(towork_ssh "mkdir -p $DL_ROOT/android && cd $DL_ROOT/android && [ -f '$FILE' ] && sha256sum '$FILE' | cut -d' ' -f1 || true")"
if [[ -n "$remote_sha" && "$remote_sha" != "$SHA256" ]]; then
  echo "服务器上已有 $FILE 且内容不同。产物不可变：请先提升 pubspec.yaml 的版本号。" >&2
  exit 1
fi

chmod -R u=rwX,go=rX "$STAGE"
if [[ -z "$remote_sha" ]]; then
  rsync -rlpz --partial --progress -e "$SSH_CMD" "$STAGE/android/$FILE" "$TOWORK_HOST:$DL_ROOT/android/.upload.$SHA256.apk"
fi
for patch_file in "$STAGE"/android/*.hpatch; do
  [[ -f "$patch_file" ]] || continue
  patch_sha="$(shasum -a 256 "$patch_file" | awk '{print $1}')"
  rsync -rlpz --partial -e "$SSH_CMD" "$patch_file" "$TOWORK_HOST:$DL_ROOT/android/.upload.$patch_sha.hpatch"
done
MANIFEST_STAGE="latest.$SHA256.json"
rsync -rlpz -e "$SSH_CMD" "$STAGE/latest.json" "$TOWORK_HOST:$DL_ROOT/$MANIFEST_STAGE"
towork_ssh "cd $DL_ROOT && flock .publish.lock python3 - '$MANIFEST_STAGE'" < tool/promote_android_release.py

echo "已发布：$PUBLIC_BASE/android/$FILE"
curl -fsS -o /dev/null -w "latest.json -> %{http_code}\n" "$PUBLIC_BASE/latest.json"

#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-${TOWORK_HOST:?Set the release SSH alias}}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/website/"
DEST="${TOWORK_SITE_DIR:?Set the website directory}"

TOWORK_HOST="$HOST"
source "$ROOT/tool/_server_ssh.sh"

towork_check_path "$DEST" towork
for f in index.html styles.css app.js assets/icon-256.png; do
  [[ -f "$SRC$f" ]] || { echo "缺少 website/$f" >&2; exit 1; }
done

# 用内容哈希替换 index.html 里静态资源的 ?v=…，避免浏览器缓存旧 CSS/JS
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
rsync -a --exclude README.md "$SRC" "$STAGE/"
css_v="$(shasum -a 256 "$STAGE/styles.css" | cut -c1-10)"
js_v="$(shasum -a 256 "$STAGE/app.js" | cut -c1-10)"
sed -i.bak -e "s|styles.css?v=[^\"]*|styles.css?v=$css_v|" \
           -e "s|app.js?v=[^\"]*|app.js?v=$js_v|" "$STAGE/index.html"
rm -f "$STAGE/index.html.bak"

towork_ssh "mkdir -p $DEST"
chmod -R u=rwX,go=rX "$STAGE"   # macOS 自带 openrsync 不支持 --chmod
rsync -rlpz --delete -e "$SSH_CMD" "$STAGE/" "$HOST:$DEST/"

echo "已发布到 $HOST:$DEST"
curl -fsS -o /dev/null -w "https://zhaozhaoyue.top/towork/ -> %{http_code}\n" https://zhaozhaoyue.top/towork/

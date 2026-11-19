: "${TOWORK_HOST:?Set the release SSH host alias}"
towork_check_path() {
  [[ "$1" =~ ^/([a-zA-Z0-9_-]+/)*$2$ ]] || { echo "Invalid ToWork deployment directory" >&2; return 1; }
}
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)
if [[ "${TOWORK_SSH_DIRECT:-0}" == "1" ]]; then
  _iface="${TOWORK_SSH_IFACE:-$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')}"
  if [[ "$_iface" == utun* || -z "$_iface" ]]; then
    _iface="$(networksetup -listallhardwareports 2>/dev/null | awk '/^Device:/{print $2}' \
      | while read -r d; do ipconfig getifaddr "$d" >/dev/null 2>&1 && { echo "$d"; break; }; done)"
  fi
  [[ -n "$_iface" ]] && SSH_OPTS+=(-o "ProxyCommand=nc -b $_iface %h %p")
fi
# rsync -e 按自己的规则分词，单引号保住含空格的 ProxyCommand（兼容 macOS 自带 bash 3.2）
SSH_CMD="ssh"
for _o in "${SSH_OPTS[@]}"; do SSH_CMD+=" '$_o'"; done

towork_ssh() { ssh "${SSH_OPTS[@]}" "$TOWORK_HOST" "$@"; }

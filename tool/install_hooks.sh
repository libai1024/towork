#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
hooks="$(git rev-parse --git-path hooks)"
mkdir -p "$hooks"
for name in pre-commit commit-msg pre-push; do
  if [[ -e "$hooks/$name" ]] && ! cmp -s ".githooks/$name" "$hooks/$name"; then
    echo "Existing hook needs composition: $hooks/$name" >&2
    exit 1
  fi
done
for name in pre-commit commit-msg pre-push; do
  cp ".githooks/$name" "$hooks/$name"
  chmod +x "$hooks/$name"
done
echo "Installed ToWork hooks in $hooks"

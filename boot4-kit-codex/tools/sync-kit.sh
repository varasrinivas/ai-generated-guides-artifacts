#!/usr/bin/env bash
# tools/sync-kit.sh — in the kit repo. Vendor/update ONE service repo.
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?usage: sync-kit.sh <path-to-service-repo>}"
VER="$(git -C "$KIT" rev-parse --short HEAD)"

git -C "$REPO" switch -c "chore/boot4-kit-$VER"
mkdir -p "$REPO/.agents" "$REPO/.codex"
rm -rf "$REPO/.agents/skills" "$REPO/.codex/agents"
cp -R "$KIT/.agents/skills" "$REPO/.agents/"
cp -R "$KIT/.codex/agents"  "$REPO/.codex/"
cp    "$KIT/.codex/hooks.json" "$REPO/.codex/hooks.json"
# config.toml is per-repo — never overwritten; warn if it is missing
[ -f "$REPO/.codex/config.toml" ] ||
  echo ">>> copy $KIT/.codex/config.toml into $REPO/.codex/ (one-time)"
# profiles are USER-level: they cannot be vendored into the repo
[ -f "$HOME/.codex/boot4-loop.config.toml" ] ||
  echo ">>> copy $KIT/codex-profiles/*.config.toml into ~/.codex/ (one-time)"
git -C "$REPO" add .agents .codex
git -C "$REPO" commit -m "chore: sync boot4 kit @ $VER"
# then: git push -u origin HEAD && gh pr create --fill

# ---- the whole fleet, from one terminal ----
# while read -r r; do ./tools/sync-kit.sh "$r"; done < repos.txt

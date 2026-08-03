#!/usr/bin/env bash
# Vendor (or update) the boot4 kit into ONE service repo — the sync-PR path.
#
# The kit repo stays the single source of truth. Consuming repos get plain
# files under .agents/ and .codex/, delivered on a branch so the PR review is
# the adoption gate. Run from a laptop; no CI involved.
#
# Usage:        ./tools/sync-kit.sh ../order-service
# Whole fleet:  while read -r r; do ./tools/sync-kit.sh "$r"; done < repos.txt
#
# Mapping from the kit layout:
#   .agents/skills/     -> <repo>/.agents/skills    (kit-owned, replaced)
#   .codex/agents/      -> <repo>/.codex/agents     (kit-owned, replaced)
#   .codex/hooks.json   -> <repo>/.codex/hooks.json (Codex reads this file
#                          directly, so there is no merge step)
#   examples/config.toml-> NOT copied: .codex/config.toml is per-repo and
#                          carries the sandbox and approval policy. It sits
#                          under examples/ so it does not configure THIS
#                          repo. Warned about once.
#   codex-profiles/*    -> ~/.codex/ by hand: profiles are user-level and
#                          cannot be vendored into a repo.
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?usage: sync-kit.sh <path-to-service-repo>}"
VER="$(git -C "$KIT" rev-parse --short HEAD)"
BRANCH="chore/boot4-kit-$VER"

if ! git -C "$REPO" diff --quiet || ! git -C "$REPO" diff --cached --quiet; then
  echo "ERROR: $REPO has uncommitted changes; sync onto a clean tree." >&2
  exit 1
fi

git -C "$REPO" switch -c "$BRANCH" 2>/dev/null || git -C "$REPO" switch "$BRANCH"

mkdir -p "$REPO/.agents" "$REPO/.codex"
rm -rf "$REPO/.agents/skills" "$REPO/.codex/agents"
cp -R "$KIT/.agents/skills" "$REPO/.agents/"
cp -R "$KIT/.codex/agents"  "$REPO/.codex/"
cp    "$KIT/.codex/hooks.json" "$REPO/.codex/hooks.json"

if [ ! -f "$REPO/.codex/config.toml" ]; then
  echo ">>> $REPO/.codex/config.toml is missing."
  echo ">>> One-time step: copy $KIT/examples/config.toml into $REPO/.codex/."
fi
if [ ! -f "$HOME/.codex/boot4-loop.config.toml" ]; then
  echo ">>> Profiles are user-level and cannot be vendored into a repo."
  echo ">>> One-time step: copy $KIT/codex-profiles/*.config.toml into ~/.codex/."
fi

git -C "$REPO" add .agents .codex
if git -C "$REPO" diff --cached --quiet; then
  echo "$REPO already up to date with kit @ $VER"
  exit 0
fi
git -C "$REPO" commit -m "chore: sync boot4 kit @ $VER"

echo "Branch $BRANCH ready in $REPO. Next:"
echo "  git -C \"$REPO\" push -u origin \"$BRANCH\" && gh pr create --fill"

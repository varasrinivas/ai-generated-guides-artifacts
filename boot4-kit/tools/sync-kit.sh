#!/usr/bin/env bash
# Vendor (or update) the boot4 kit into ONE service repo — the no-plugin path.
#
# The kit repo stays the single source of truth. Consuming repos get plain
# files under .claude/, delivered on a branch so the PR review is the
# adoption gate. Run from a laptop; no CI involved.
#
# Usage:        ./tools/sync-kit.sh ../order-service
# Whole fleet:  while read -r r; do ./tools/sync-kit.sh "$r"; done < repos.txt
#
# Mapping from the plugin layout:
#   skills/  agents/        -> <repo>/.claude/skills  <repo>/.claude/agents
#   hooks/hooks.json        -> merge into <repo>/.claude/settings.json "hooks"
#                              block by hand, ONCE (settings.json is per-repo:
#                              it also carries permissions; never overwritten)
#   .claude-plugin/*        -> not copied; nothing reads manifests when vendored
# Note: vendored commands have no namespace — /migrate-phase, not
# /boot4-kit:migrate-phase.
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

mkdir -p "$REPO/.claude"
rm -rf "$REPO/.claude/skills" "$REPO/.claude/agents"
cp -R "$KIT/skills" "$KIT/agents" "$REPO/.claude/"

if ! grep -q '"PostToolUse"' "$REPO/.claude/settings.json" 2>/dev/null; then
  echo ">>> $REPO/.claude/settings.json has no PostToolUse hook."
  echo ">>> One-time step: merge the hooks block from $KIT/hooks/hooks.json."
fi

git -C "$REPO" add .claude
if git -C "$REPO" diff --cached --quiet; then
  echo "$REPO already up to date with kit @ $VER"
  exit 0
fi
git -C "$REPO" commit -m "chore: sync boot4 kit @ $VER"

echo "Branch $BRANCH ready in $REPO. Next:"
echo "  git -C \"$REPO\" push -u origin \"$BRANCH\" && gh pr create --fill"

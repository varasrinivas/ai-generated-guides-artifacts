#!/usr/bin/env bash
# Vendor (or update) the boot4 kit into ONE service repo — the sync-PR path.
#
# The kit repo stays the single source of truth. Consuming repos get plain
# files under .github/, delivered on a branch so the PR review is the
# adoption gate. Run from a laptop; no CI involved.
#
# Usage:        ./tools/sync-kit.sh ../order-service
# Whole fleet:  while read -r r; do ./tools/sync-kit.sh "$r"; done < repos.txt
#
# Mapping from the kit layout:
#   skills/          -> <repo>/.github/skills       (kit-owned, replaced)
#   agents/          -> <repo>/.github/agents       (kit-owned, replaced)
#   hooks/hooks.json -> <repo>/.github/hooks/boot4.json  (Copilot reads
#                       repo hooks from .github/hooks/*.json directly, so
#                       there is no merge step — but they apply to EVERY
#                       Copilot agent run in the repo, CLI and cloud alike;
#                       the sync PR review is where a repo accepts that)
#   AGENTS.md        -> NOT copied: the charter is per-repo. Copy it once
#                       by hand, edit in the repo's real facts, commit.
#                       Warned about below.
# Tool approvals are user-level (session flags, or saved per-location
# approvals in ~/.copilot/permissions-config.json) — nothing to vendor.
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

mkdir -p "$REPO/.github/hooks"
rm -rf "$REPO/.github/skills" "$REPO/.github/agents"
cp -R "$KIT/skills" "$REPO/.github/skills"
cp -R "$KIT/agents" "$REPO/.github/agents"
cp    "$KIT/hooks/hooks.json" "$REPO/.github/hooks/boot4.json"

if [ ! -f "$REPO/AGENTS.md" ]; then
  echo ">>> $REPO/AGENTS.md is missing."
  echo ">>> One-time step: copy $KIT/AGENTS.md into $REPO, edit in the"
  echo ">>> repo's real modules, build commands and rules, and commit."
fi

git -C "$REPO" add .github
if git -C "$REPO" diff --cached --quiet; then
  echo "$REPO already up to date with kit @ $VER"
  exit 0
fi
git -C "$REPO" commit -m "chore: sync boot4 kit @ $VER"

echo "Branch $BRANCH ready in $REPO. Next:"
echo "  git -C \"$REPO\" push -u origin \"$BRANCH\" && gh pr create --fill"

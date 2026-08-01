#!/usr/bin/env bash
# Capture golden JSON fixtures from the PRE-migration branch.
#
# Run this on the Boot 3.5.x branch with the app running locally, THEN run the
# characterization tests on the migration branch against the same fixtures.
# Every diff is a Tier-3 finding to explain, not an accident to accept.
#
# Usage:
#   BASE_URL=http://localhost:8080 ./capture-goldens.sh
#
# Configuration:
#   BASE_URL        app under test        (default http://localhost:8080)
#   OUT_DIR         fixture output dir    (default src/test/resources/goldens)
#   ENDPOINTS_FILE  one GET path per line (default goldens-endpoints.txt)
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
OUT_DIR="${OUT_DIR:-src/test/resources/goldens}"
ENDPOINTS_FILE="${ENDPOINTS_FILE:-goldens-endpoints.txt}"

if [[ ! -f "$ENDPOINTS_FILE" ]]; then
  echo "ERROR: $ENDPOINTS_FILE not found." >&2
  echo "Create it with one GET path per line, e.g.:" >&2
  echo "  /api/orders/42" >&2
  echo "  /api/customers?page=0&size=5" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
count=0

while IFS= read -r path; do
  [[ -z "$path" || "$path" == \#* ]] && continue
  # Stable file name: strip leading slash, replace separators
  name=$(echo "${path#/}" | tr '/?&=' '__--')
  out="$OUT_DIR/$name.json"
  echo "GET $BASE_URL$path -> $out"
  body=$(curl -sfS "$BASE_URL$path")
  # Pretty-print for reviewable diffs when jq is available.
  # NOTE: raw bytes, NOT normalized — Jackson 3 changes key order and date
  # formats, and catching exactly that is the point of these fixtures.
  if command -v jq >/dev/null 2>&1; then
    echo "$body" | jq . > "$out"
  else
    echo "$body" > "$out"
  fi
  count=$((count + 1))
done < "$ENDPOINTS_FILE"

echo "Captured $count golden fixture(s) in $OUT_DIR"
echo "Commit them on the pre-bump branch before starting Phase 3."

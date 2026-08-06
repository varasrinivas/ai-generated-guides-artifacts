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
#
# Every failure here is loud and non-zero, deliberately. A run that captures
# nothing but exits 0 leaves Phase 6 comparing nothing against nothing and
# finding no differences — which is indistinguishable from "no behaviour
# changed", and is the one wrong answer this whole exercise exists to avoid.
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
OUT_DIR="${OUT_DIR:-src/test/resources/goldens}"
ENDPOINTS_FILE="${ENDPOINTS_FILE:-goldens-endpoints.txt}"

command -v curl >/dev/null 2>&1 || {
  echo "ERROR: curl is not on PATH; this script cannot capture anything." >&2
  exit 1
}

if [[ ! -f "$ENDPOINTS_FILE" ]]; then
  echo "ERROR: $ENDPOINTS_FILE not found." >&2
  echo "Create it with one GET path per line, e.g.:" >&2
  echo "  /api/orders/42" >&2
  echo "  /api/customers?page=0&size=5" >&2
  exit 1
fi

# Reachability preflight. No -f: a 401 or 404 on the root path still proves the
# app is answering, and that is all this checks.
if ! curl -sS -o /dev/null --max-time 10 "$BASE_URL" 2>/dev/null; then
  echo "ERROR: $BASE_URL is not answering." >&2
  echo "       Start the app on the PRE-bump branch first — goldens are only" >&2
  echo "       meaningful if they record Boot 3.5.x behaviour." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
count=0

# `|| [[ -n "$path" ]]` keeps the final line when the file has no trailing
# newline; without it that endpoint is dropped and nobody is told.
while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -z "$path" || "$path" == \#* ]] && continue
  # Stable file name: strip leading slash, replace separators. Done with
  # parameter expansion rather than `tr '/?&=' '__--'`, whose SET2 GNU tr
  # reads as the range _ to -, erroring out on every path it is given.
  name="${path#/}"
  name="${name//[\/?]/_}"
  name="${name//[&=]/-}"
  out="$OUT_DIR/$name.json"
  echo "GET $BASE_URL$path -> $out"
  body=$(curl -sfS "$BASE_URL$path")
  # Pretty-print for reviewable diffs when jq is available.
  # NOTE: raw bytes, NOT normalized — Jackson 3 changes key order and date
  # formats, and catching exactly that is the point of these fixtures.
  # Written via a temp file so a jq failure on a non-JSON body cannot leave a
  # truncated fixture behind that a later run would treat as the golden.
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$body" | jq . > "$out.tmp"
    mv "$out.tmp" "$out"
  else
    printf '%s\n' "$body" > "$out"
  fi
  count=$((count + 1))
done < "$ENDPOINTS_FILE"

if [[ "$count" -eq 0 ]]; then
  echo "ERROR: $ENDPOINTS_FILE lists no endpoints, so nothing was captured." >&2
  echo "       Exiting non-zero on purpose: an empty golden set makes Phase 6" >&2
  echo "       find no differences, which reads exactly like no regression." >&2
  exit 1
fi

echo "Captured $count golden fixture(s) in $OUT_DIR"
echo "Commit them on the pre-bump branch before starting Phase 3."

#!/usr/bin/env bash
# Run every security/items/**/check.sh and print a compact matrix.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

printf '%-50s %-8s %s\n' "ITEM" "STATUS" "SUMMARY"
printf '%-50s %-8s %s\n' "----" "------" "-------"

while IFS= read -r -d '' check; do
  dir=$(dirname "$check")
  rel=${dir#"$ROOT"/}
  # skip template
  case "$rel" in
    _template|*/_template) continue ;;
  esac
  chmod +x "$check" 2>/dev/null || true
  out=$(cd "$dir" && ./check.sh 2>/dev/null || true)
  # last non-empty line as JSON
  json=$(printf '%s\n' "$out" | awk 'NF{p=$0} END{print p}')
  status=$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(d.get("status","?"))' "$json" 2>/dev/null || echo error)
  summary=$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(d.get("summary","")[:80])' "$json" 2>/dev/null || echo "invalid json")
  printf '%-50s %-8s %s\n' "$rel" "$status" "$summary"
done < <(find "$ROOT" -type f -name check.sh -print0 | sort -z)

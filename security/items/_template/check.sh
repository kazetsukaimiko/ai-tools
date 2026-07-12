#!/usr/bin/env bash
# Optional read-only check. Print one JSON object; exit 0 on successful run.
set -euo pipefail
python3 - <<'PY'
import json
print(json.dumps({
    "status": "skip",
    "summary": "template checker — replace with a real check",
    "evidence": {},
    "fix_hint": "Edit check.sh or remove check: from ITEM.md",
}))
PY

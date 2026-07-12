#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, shutil, subprocess

evidence = {}
# ufw status is often readable without elevation
if shutil.which("ufw"):
    try:
        r = subprocess.run(
            ["ufw", "status", "verbose"],
            capture_output=True, text=True, timeout=15,
        )
        text = (r.stdout or "") + (r.stderr or "")
        evidence["ufw_status_snippet"] = "\n".join(text.splitlines()[:15])
        low = text.lower()
        if "status: active" in low and "deny (incoming)" in low:
            print(json.dumps({
                "status": "pass",
                "summary": "ufw active with default deny (incoming)",
                "evidence": evidence,
            }))
            raise SystemExit(0)
        if "status: active" in low:
            print(json.dumps({
                "status": "warn",
                "summary": "ufw active but default incoming policy not clearly deny",
                "evidence": evidence,
                "fix_hint": "Review `ufw status verbose` with the user.",
            }))
            raise SystemExit(0)
    except SystemExit:
        raise
    except Exception as e:
        evidence["ufw_error"] = str(e)

print(json.dumps({
    "status": "skip",
    "summary": "No high-confidence default-deny signal without privileged policy dump",
    "evidence": evidence,
    "fix_hint": "Review firewalld zones or nftables with the user; elevate only if they want a full rules listing.",
}))
PY

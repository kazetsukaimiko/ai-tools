#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, shutil, subprocess

vectors = []
if shutil.which("firefox"):
    vectors.append({"vector": "system-firefox", "path": shutil.which("firefox")})

flatpak = shutil.which("flatpak")
if flatpak:
    try:
        r = subprocess.run(
            [flatpak, "list", "--app", "--columns=application"],
            capture_output=True, text=True, timeout=30,
        )
        apps = {line.strip() for line in r.stdout.splitlines() if line.strip()}
        if "org.mozilla.firefox" in apps:
            vectors.append({"vector": "flatpak-firefox", "app_id": "org.mozilla.firefox"})
    except Exception as e:
        print(json.dumps({
            "status": "error",
            "summary": f"flatpak list failed: {e}",
            "evidence": {},
        }))
        raise SystemExit(2)

if vectors:
    status, summary = "pass", "Firefox found via: " + ", ".join(v["vector"] for v in vectors)
else:
    status, summary = "fail", "No system firefox binary or org.mozilla.firefox Flatpak app detected"

print(json.dumps({
    "status": status,
    "summary": summary,
    "evidence": {"vectors": vectors, "home": os.path.expanduser("~")},
    "fix_hint": "Install Firefox from your distro or Flatpak if you want Firefox-based checklist items.",
}))
PY

#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, shutil, subprocess

found = []
for name in ("element-desktop", "element", "signal-desktop", "signal"):
    path = shutil.which(name)
    if path:
        found.append({"tool": name, "path": path})

if shutil.which("flatpak"):
    try:
        r = subprocess.run(
            ["flatpak", "list", "--app", "--columns=application"],
            capture_output=True, text=True, timeout=30,
        )
        for line in r.stdout.splitlines():
            app = line.strip()
            low = app.lower()
            if "element" in low or "vector" in low or "signal" in low or "schildichat" in low:
                found.append({"tool": "flatpak:" + app})
    except Exception as e:
        found.append({"flatpak_error": str(e)})

if found:
    status, summary = "pass", "E2EE chat client tooling present"
else:
    status, summary = "fail", "No Element/Signal-class desktop client detected (greenlist gap)"

print(json.dumps({
    "status": status,
    "summary": summary,
    "evidence": {"found": found},
    "fix_hint": "Install Element Desktop or Signal (package or Flatpak).",
}))
PY

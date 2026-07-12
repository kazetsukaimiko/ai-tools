#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, shutil, subprocess

found = []
for name in ("wg", "wg-quick", "nmcli", "openvpn", "mullvad", "protonvpn", "tailscale"):
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
            if any(k in low for k in ("mullvad", "protonvpn", "wireguard", "openvpn", "tailscale", "ivpn", "mozillavpn")):
                found.append({"tool": "flatpak:" + app})
    except Exception as e:
        found.append({"flatpak_error": str(e)})

if found:
    status, summary = "pass", "VPN-related tooling present"
else:
    status, summary = "warn", "No common VPN client tools detected (optional for many threat models)"

print(json.dumps({
    "status": status,
    "summary": summary,
    "evidence": {"found": found},
    "fix_hint": "Install WireGuard or your provider’s Linux/Flatpak client if you want VPN capability.",
}))
PY

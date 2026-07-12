#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, shutil, subprocess

def active_unit(name: str) -> str | None:
    if not shutil.which("systemctl"):
        return None
    try:
        r = subprocess.run(
            ["systemctl", "is-active", name],
            capture_output=True, text=True, timeout=10,
        )
        return (r.stdout or r.stderr or "").strip() or None
    except Exception:
        return None

evidence = {
    "firewalld": active_unit("firewalld"),
    "ufw": active_unit("ufw"),
    "nft": bool(shutil.which("nft")),
    "iptables": bool(shutil.which("iptables")),
    "firewall-cmd": bool(shutil.which("firewall-cmd")),
}

if evidence["firewalld"] == "active" or evidence["ufw"] == "active":
    status = "pass"
    summary = "Firewall service active (" + (
        "firewalld" if evidence["firewalld"] == "active" else "ufw"
    ) + ")"
elif evidence["nft"] or evidence["iptables"] or evidence["firewall-cmd"]:
    status = "warn"
    summary = "Firewall tools present but no active firewalld/ufw service detected"
elif evidence["firewalld"] in ("inactive", "failed") or evidence["ufw"] in ("inactive", "failed"):
    status = "warn"
    summary = "Firewall unit installed but not active"
else:
    status = "fail"
    summary = "No common host firewall stack detected (greenlist gap)"

print(json.dumps({
    "status": status,
    "summary": summary,
    "evidence": evidence,
    "fix_hint": "Enable firewalld or ufw, or adopt a maintained nftables policy — with user consent.",
}))
PY

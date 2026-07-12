#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, shutil, subprocess

if not shutil.which("timedatectl"):
    print(json.dumps({
        "status": "skip",
        "summary": "timedatectl not available",
        "evidence": {},
    }))
    raise SystemExit(0)

r = subprocess.run(["timedatectl", "show"], capture_output=True, text=True, timeout=15)
if r.returncode != 0:
    # fallback parse status text
    r2 = subprocess.run(["timedatectl", "status"], capture_output=True, text=True, timeout=15)
    text = r2.stdout or ""
    evidence = {"timedatectl_status": text[:500]}
    low = text.lower()
    if "system clock synchronized: yes" in low:
        status, summary = "pass", "System clock synchronized (timedatectl status)"
    elif "system clock synchronized: no" in low:
        status, summary = "fail", "System clock not synchronized (greenlist gap)"
    else:
        status, summary = "warn", "Could not parse timedatectl status"
    print(json.dumps({"status": status, "summary": summary, "evidence": evidence,
                      "fix_hint": "Enable systemd-timesyncd or chrony; verify with timedatectl."}))
    raise SystemExit(0)

props = {}
for line in (r.stdout or "").splitlines():
    if "=" in line:
        k, v = line.split("=", 1)
        props[k.strip()] = v.strip()

ntp = props.get("NTP", props.get("NetworkTimeProtocol", ""))
synced = props.get("NTPSynchronized", props.get("SystemClockSynchronized", ""))
evidence = {"NTP": ntp, "NTPSynchronized": synced, "raw_keys": sorted(props.keys())[:20]}

if synced.lower() in ("yes", "true", "1"):
    status, summary = "pass", "NTPSynchronized=yes"
elif synced.lower() in ("no", "false", "0"):
    status, summary = "fail", "Clock not synchronized (greenlist gap)"
else:
    status, summary = "warn", "Ambiguous timedatectl show output"

print(json.dumps({
    "status": status,
    "summary": summary,
    "evidence": evidence,
    "fix_hint": "Enable systemd-timesyncd or chrony; verify with timedatectl.",
}))
PY

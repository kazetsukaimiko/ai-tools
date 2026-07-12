#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, shutil, subprocess
from pathlib import Path

UBLOCK_IDS = {
    "uBlock0@raymondhill.net",
    "ublock0@raymondhill.net",
}
HOME = Path(os.path.expanduser("~"))


def flatpak_apps() -> set[str]:
    if not shutil.which("flatpak"):
        return set()
    try:
        r = subprocess.run(
            ["flatpak", "list", "--app", "--columns=application"],
            capture_output=True, text=True, timeout=30,
        )
        return {line.strip() for line in r.stdout.splitlines() if line.strip()}
    except Exception:
        return set()


def firefox_installed() -> tuple[bool, list[dict]]:
    """Only treat Firefox as present if a real install vector exists (not leftover profiles)."""
    vectors = []
    path = shutil.which("firefox")
    if path:
        vectors.append({"vector": "system-firefox", "path": path})
    apps = flatpak_apps()
    if "org.mozilla.firefox" in apps:
        vectors.append({"vector": "flatpak-firefox", "app_id": "org.mozilla.firefox"})
    return bool(vectors), vectors


def profile_roots():
    roots = []
    sys_ff = HOME / ".mozilla" / "firefox"
    if sys_ff.is_dir():
        roots.append(("system-firefox", sys_ff))
    fp = HOME / ".var" / "app" / "org.mozilla.firefox" / ".mozilla" / "firefox"
    if fp.is_dir():
        roots.append(("flatpak-firefox", fp))
    return roots


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return None


def addons_from_extensions_json(data):
    return data.get("addons") or []


def addons_from_addons_json(data):
    if isinstance(data, list):
        return data
    return data.get("addons") or []


def addon_matches(addon) -> bool:
    if not isinstance(addon, dict):
        return False
    aid = (addon.get("id") or addon.get("addonID") or "").strip()
    if aid in UBLOCK_IDS:
        return True
    loc = addon.get("defaultLocale") or {}
    name = (loc.get("name") or addon.get("name") or "").lower()
    return "ublock origin" in name


def activeish(addon) -> bool:
    if "active" in addon:
        return bool(addon.get("active"))
    return True


installed, install_vectors = firefox_installed()
if not installed:
    print(json.dumps({
        "status": "skip",
        "summary": "Firefox not installed; plugin checks do not apply",
        "evidence": {"install_vectors": []},
        "fix_hint": None,
    }))
    raise SystemExit(0)

roots = profile_roots()
found = []
scanned = []
for vector, root in roots:
    if not root.is_dir():
        continue
    for prof in root.iterdir():
        if not prof.is_dir() or prof.name.startswith("."):
            continue
        for fname, loader in (
            ("extensions.json", addons_from_extensions_json),
            ("addons.json", addons_from_addons_json),
        ):
            path = prof / fname
            if not path.is_file():
                continue
            scanned.append(str(path))
            data = load_json(path)
            if data is None:
                continue
            for addon in loader(data):
                if addon_matches(addon):
                    found.append({
                        "vector": vector,
                        "profile": prof.name,
                        "id": addon.get("id") or addon.get("addonID"),
                        "active": activeish(addon),
                        "source": fname,
                    })

if found:
    any_active = any(f.get("active", True) for f in found)
    print(json.dumps({
        "status": "pass" if any_active else "warn",
        "summary": (
            "uBlock Origin present"
            + ("" if any_active else " but marked inactive in profile data")
        ),
        "evidence": {
            "install_vectors": install_vectors,
            "matches": found,
            "scanned_files": len(scanned),
        },
        "fix_hint": "Enable the extension in about:addons if inactive.",
    }))
elif scanned:
    print(json.dumps({
        "status": "fail",
        "summary": "Firefox installed but uBlock Origin not detected (greenlist gap)",
        "evidence": {
            "install_vectors": install_vectors,
            "scanned_files": scanned[:20],
            "scanned_count": len(scanned),
        },
        "fix_hint": "Install uBlock Origin from Mozilla AMO in each Firefox you use (system and Flatpak are separate).",
    }))
else:
    print(json.dumps({
        "status": "warn",
        "summary": "Firefox is installed but no profile extension metadata found yet",
        "evidence": {
            "install_vectors": install_vectors,
            "roots_checked": [str(r) for _, r in roots],
        },
        "fix_hint": "Start Firefox once to create a profile, then install uBlock Origin.",
    }))
PY

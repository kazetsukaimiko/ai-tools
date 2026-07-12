#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, shutil, subprocess

REQUIRED = [
    # (logical_name, package name candidates)
    ("xdg-desktop-portal", ["xdg-desktop-portal"]),
    ("xdg-desktop-portal-kde", ["xdg-desktop-portal-kde"]),
    ("flatpak-kcm", ["flatpak-kcm"]),
]


def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "").strip(), (r.stderr or "").strip()
    except Exception as e:
        return 1, "", str(e)


def is_kde() -> bool:
    desk = " ".join(
        filter(
            None,
            [
                os.environ.get("XDG_CURRENT_DESKTOP", ""),
                os.environ.get("DESKTOP_SESSION", ""),
                os.environ.get("XDG_SESSION_DESKTOP", ""),
            ],
        )
    ).lower()
    return any(k in desk for k in ("kde", "plasma"))


def package_installed(names: list[str]) -> tuple[bool, str | None, str | None]:
    """Return (ok, matched_name, version)."""
    if shutil.which("pacman"):
        for n in names:
            code, out, _ = run(["pacman", "-Q", n])
            if code == 0 and out:
                # "name version"
                parts = out.split()
                ver = parts[1] if len(parts) > 1 else out
                return True, n, ver
    if shutil.which("dpkg-query"):
        for n in names:
            code, out, _ = run(["dpkg-query", "-W", "-f=${Package} ${Version}", n])
            if code == 0 and out and not out.lower().startswith("no packages"):
                parts = out.split()
                return True, parts[0], parts[1] if len(parts) > 1 else ""
    if shutil.which("rpm"):
        for n in names:
            code, out, _ = run(["rpm", "-q", n, "--qf", "%{NAME} %{VERSION}-%{RELEASE}"])
            if code == 0 and out and "not installed" not in out.lower():
                parts = out.split()
                return True, parts[0], parts[1] if len(parts) > 1 else ""
    # file-level fallback for portals
    return False, None, None


if not shutil.which("flatpak"):
    print(json.dumps({
        "status": "skip",
        "summary": "flatpak not installed; KDE Flatpak integration check skipped",
        "evidence": {},
    }))
    raise SystemExit(0)

if not is_kde():
    print(json.dumps({
        "status": "skip",
        "summary": "Session does not look like KDE/Plasma; KDE Flatpak packages not required here",
        "evidence": {
            "XDG_CURRENT_DESKTOP": os.environ.get("XDG_CURRENT_DESKTOP"),
            "DESKTOP_SESSION": os.environ.get("DESKTOP_SESSION"),
        },
    }))
    raise SystemExit(0)

present = {}
missing = []
for label, candidates in REQUIRED:
    ok, name, ver = package_installed(candidates)
    present[label] = {"installed": ok, "package": name, "version": ver, "candidates": candidates}
    if not ok:
        missing.append(label)

if missing:
    print(json.dumps({
        "status": "fail",
        "summary": "KDE Flatpak integration packages missing: " + ", ".join(missing),
        "evidence": {"packages": present, "missing": missing},
        "fix_hint": (
            "Install xdg-desktop-portal, xdg-desktop-portal-kde, and flatpak-kcm "
            "via the distro package manager (pkexec). Then re-check."
        ),
    }))
else:
    print(json.dumps({
        "status": "pass",
        "summary": "KDE Flatpak portal + Permissions KCM packages are installed",
        "evidence": {"packages": present},
    }))
PY

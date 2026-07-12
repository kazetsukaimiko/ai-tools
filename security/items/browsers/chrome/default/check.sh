#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, re, shutil, subprocess

# Desktop-file / app-id classification
GOOGLE_CHROME = re.compile(
    r"(?i)(^|/)(google-chrome|google-chrome-stable|google-chrome-beta|google-chrome-unstable|"
    r"com\.google\.Chrome)(\.desktop)?$"
)
# Stock chromium — not ungoogled
STOCK_CHROMIUM = re.compile(
    r"(?i)(^|/)(chromium|chromium-browser|org\.chromium\.Chromium)(\.desktop)?$"
)
UNGOOGLED = re.compile(
    r"(?i)ungoogled|io\.github\.ungoogled"
)


def classify(desktop: str) -> str:
    """Return 'google-chrome' | 'stock-chromium' | 'ungoogled-chromium' | 'other'."""
    d = (desktop or "").strip()
    if not d:
        return "other"
    base = d.split("/")[-1]
    if UNGOOGLED.search(d) or UNGOOGLED.search(base):
        return "ungoogled-chromium"
    if GOOGLE_CHROME.search(base) or GOOGLE_CHROME.search(d):
        return "google-chrome"
    if STOCK_CHROMIUM.search(base) or STOCK_CHROMIUM.search(d):
        # avoid matching something weird containing chromium after ungoogled already handled
        if UNGOOGLED.search(d):
            return "ungoogled-chromium"
        return "stock-chromium"
    return "other"


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return (r.stdout or "").strip(), r.returncode
    except Exception as e:
        return str(e), 1


def default_browser() -> str | None:
    if shutil.which("xdg-settings"):
        out, code = run(["xdg-settings", "get", "default-web-browser"])
        if code == 0 and out and "error" not in out.lower():
            return out.splitlines()[0].strip()
    if shutil.which("xdg-mime"):
        out, code = run(["xdg-mime", "query", "default", "x-scheme-handler/https"])
        if code == 0 and out:
            return out.splitlines()[0].strip()
        out, code = run(["xdg-mime", "query", "default", "x-scheme-handler/http"])
        if code == 0 and out:
            return out.splitlines()[0].strip()
    return None


def installed_flagged() -> list[dict]:
    found = []
    for name in (
        "google-chrome",
        "google-chrome-stable",
        "google-chrome-beta",
        "chromium",
        "chromium-browser",
    ):
        path = shutil.which(name)
        if path:
            kind = "google-chrome" if "chrome" in name else "stock-chromium"
            found.append({"tool": name, "path": path, "kind": kind})
    # ungoogled often ships as ungoogled-chromium
    for name in ("ungoogled-chromium", "ungoogled-chromium-bin"):
        path = shutil.which(name)
        if path:
            found.append({"tool": name, "path": path, "kind": "ungoogled-chromium"})

    if shutil.which("flatpak"):
        out, code = run(["flatpak", "list", "--app", "--columns=application"])
        if code == 0:
            for line in out.splitlines():
                app = line.strip()
                if not app:
                    continue
                kind = classify(app)
                if kind in ("google-chrome", "stock-chromium", "ungoogled-chromium"):
                    found.append({"tool": "flatpak:" + app, "kind": kind})
    return found


default = default_browser()
default_kind = classify(default) if default else None
installed = installed_flagged()
has_google_or_stock = any(i["kind"] in ("google-chrome", "stock-chromium") for i in installed)

evidence = {
    "default_web_browser": default,
    "default_kind": default_kind,
    "installed": installed,
}

if default is None:
    print(json.dumps({
        "status": "warn",
        "summary": "Could not determine default web browser via xdg-settings/xdg-mime",
        "evidence": evidence,
        "fix_hint": "Check Settings → Default Applications, or install xdg-utils.",
    }))
elif default_kind in ("google-chrome", "stock-chromium"):
    print(json.dumps({
        "status": "fail",
        "summary": f"Default browser is {default_kind} ({default}) — greenlist gap",
        "evidence": evidence,
        "fix_hint": (
            "Change the default away from Google Chrome / stock Chromium. "
            "If you need a Chromium-based browser, Ungoogled Chromium is acceptable to this checklist. "
            "Do not take this item as a recommendation for any other specific browser."
        ),
    }))
elif default_kind == "ungoogled-chromium":
    print(json.dumps({
        "status": "pass",
        "summary": "Default browser is Ungoogled Chromium (not flagged)",
        "evidence": evidence,
    }))
elif has_google_or_stock:
    print(json.dumps({
        "status": "pass",
        "summary": "Google Chrome/stock Chromium may be installed but is not the default",
        "evidence": evidence,
    }))
else:
    print(json.dumps({
        "status": "pass",
        "summary": f"Default browser is not Google Chrome/stock Chromium ({default or 'unknown'})",
        "evidence": evidence,
    }))
PY

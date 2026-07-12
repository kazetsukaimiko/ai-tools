#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, re, shutil, subprocess
from pathlib import Path

try:
    from packaging.version import Version, InvalidVersion
except ImportError:
    Version = None  # type: ignore
    InvalidVersion = Exception  # type: ignore

HOME = Path(os.path.expanduser("~"))

GUI_CAT_HINTS = re.compile(
    r"(AudioVideo|Audio|Video|Graphics|Network|Office|Game|Utility|Science|"
    r"Education|Development|InstantMessaging|Chat|WebBrowser|Email|FileManager|"
    r"Viewer|Player|Recorder|Photography|Publishing|TextEditor|IDE|Debugger|"
    r"Engineering|Finance|RasterGraphics|VectorGraphics|2DGraphics|3DGraphics|"
    r"TV|Tuner|DiscBurning|Music|News|P2P|RemoteAccess|Telephony|VideoConference|"
    r"ContactManagement|Calendar|Dictionary|Documentation|Electronics|Geography|"
    r"Literature|Math|MedicalSoftware|Presentation|Scanning|Spreadsheet|"
    r"WordProcessor|X-.*Chat|X-.*Messenger)",
    re.I,
)
SKIP_CAT = re.compile(r"(TerminalEmulator|Screensaver|X-KDE-Settings|Settings)", re.I)
SKIP_NAME = re.compile(
    r"(?i)(plasma|kwin|plasmashell|systemsettings|sddm|kscreen|kded|"
    r"xdg-|pipewire|wireplumber|pulseaudio|jack |help center|drkonqi|"
    r"kinfo|kinfocenter|kwallet|polkit|discover$)"
)


def run(cmd, timeout=120):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or ""), (r.stderr or "")
    except Exception as e:
        return 1, "", str(e)


def parse_desktop(path: Path) -> dict | None:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    entry: dict[str, str] = {}
    in_entry = False
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("["):
            if s == "[Desktop Entry]":
                in_entry = True
                continue
            if in_entry:
                break
            continue
        if not in_entry or "=" not in s:
            continue
        k, v = s.split("=", 1)
        # first wins for Name/Exec (ignore locale variants for simplicity)
        if k not in entry and not k.startswith("Name["):
            entry[k] = v
        elif k == "Name" and "Name" not in entry:
            entry[k] = v
    return entry


def is_flatpak_export(path: Path) -> bool:
    try:
        rp = str(path.resolve()).lower()
    except OSError:
        rp = str(path).lower()
    return "flatpak" in rp and "export" in rp


def looks_like_gui(entry: dict) -> bool:
    if entry.get("Type", "Application") != "Application":
        return False
    if entry.get("NoDisplay", "").lower() == "true":
        return False
    if entry.get("Hidden", "").lower() == "true":
        return False
    if entry.get("Terminal", "").lower() == "true":
        return False
    cats = entry.get("Categories", "")
    if SKIP_CAT.search(cats) and not GUI_CAT_HINTS.search(cats):
        return False
    if SKIP_CAT.search(cats) and "TerminalEmulator" in cats:
        return False
    name = entry.get("Name", "")
    if SKIP_NAME.search(name):
        return False
    # Prefer apps with GUI-ish categories or explicit StartupWMClass / not only System
    if GUI_CAT_HINTS.search(cats):
        return True
    if cats == "" or cats == "Application;":
        # allow if has Icon and Exec looks graphical-ish
        return bool(entry.get("Exec") and entry.get("Icon"))
    if re.search(r"(^|;)System(;|$)", cats) and not GUI_CAT_HINTS.search(cats):
        return False
    return bool(entry.get("Exec") and entry.get("Icon"))


def desktop_dirs() -> list[Path]:
    dirs = [
        Path("/usr/share/applications"),
        Path("/usr/local/share/applications"),
        HOME / ".local/share/applications",
    ]
    xdg = os.environ.get("XDG_DATA_DIRS", "")
    for part in xdg.split(":"):
        if not part:
            continue
        p = Path(part) / "applications"
        if p not in dirs:
            dirs.append(p)
    return [d for d in dirs if d.is_dir()]


def collect_system_desktops() -> list[dict]:
    seen_ids: set[str] = set()
    out = []
    for d in desktop_dirs():
        for path in sorted(d.glob("*.desktop")):
            if is_flatpak_export(path):
                continue
            entry = parse_desktop(path)
            if not entry or not looks_like_gui(entry):
                continue
            stem = path.stem
            if stem in seen_ids:
                continue
            # skip KDE/system component reverse-dns heuristically
            if re.match(r"(?i)org\.kde\.(plasma|kwin|systemsettings|kded|ksmserver)", stem):
                continue
            if SKIP_NAME.search(stem):
                continue
            seen_ids.add(stem)
            out.append({
                "desktop_id": stem,
                "path": str(path),
                "name": entry.get("Name") or stem,
                "exec": (entry.get("Exec") or "").split()[0] if entry.get("Exec") else "",
                "categories": entry.get("Categories", ""),
            })
    return out


def package_version_for_file(path: str) -> tuple[str | None, str | None]:
    """Return (package_name, version) if known."""
    if shutil.which("pacman"):
        code, out, _ = run(["pacman", "-Qo", path], timeout=30)
        if code == 0:
            # "... is owned by pkg ver"
            m = re.search(r"is owned by (\S+) (\S+)", out)
            if m:
                return m.group(1), m.group(2)
    if shutil.which("dpkg"):
        code, out, _ = run(["dpkg", "-S", path], timeout=30)
        if code == 0 and ":" in out:
            pkg = out.split(":", 1)[0].strip().split()[-1]
            code2, out2, _ = run(["dpkg-query", "-W", "-f=${Version}", pkg], timeout=15)
            if code2 == 0 and out2.strip():
                return pkg, out2.strip()
    if shutil.which("rpm"):
        code, out, _ = run(["rpm", "-qf", path, "--qf", "%{NAME} %{VERSION}-%{RELEASE}"], timeout=30)
        if code == 0 and out.strip() and "not owned" not in out.lower():
            parts = out.strip().split(None, 1)
            if len(parts) == 2:
                return parts[0], parts[1]
    return None, None


def load_flatpak_catalog() -> list[dict]:
    code, remotes_out, _ = run(["flatpak", "remotes", "--columns=name"], timeout=30)
    remotes = [r.strip() for r in remotes_out.splitlines() if r.strip()] or ["flathub"]
    apps = []
    seen = set()
    for remote in remotes:
        code, out, err = run(
            ["flatpak", "remote-ls", remote, "--app", "--columns=application,name,version"],
            timeout=180,
        )
        if code != 0:
            continue
        for line in out.splitlines():
            # columns separated by tabs or multi-space — flatpak often uses tabs
            parts = re.split(r"\t+", line.strip())
            if len(parts) < 2:
                parts = re.split(r"\s{2,}", line.strip())
            if len(parts) < 2:
                # last resort: first token app id, rest name, no version
                toks = line.split()
                if not toks:
                    continue
                app_id, name, ver = toks[0], " ".join(toks[1:]) or toks[0], ""
            else:
                app_id = parts[0].strip()
                name = parts[1].strip() if len(parts) > 1 else app_id
                ver = parts[2].strip() if len(parts) > 2 else ""
            if not app_id or app_id in seen:
                continue
            # filter runtimes-looking
            if app_id.endswith(".Platform") or app_id.endswith(".Sdk"):
                continue
            seen.add(app_id)
            apps.append({"remote": remote, "app_id": app_id, "name": name, "version": ver})
    return apps


def installed_flatpak_ids() -> set[str]:
    code, out, _ = run(["flatpak", "list", "--app", "--columns=application"], timeout=60)
    if code != 0:
        return set()
    return {line.strip() for line in out.splitlines() if line.strip()}


def norm_name(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def version_gte(flatpak_ver: str, system_ver: str) -> bool | None:
    """True if flatpak >= system; False if lower; None if incomparable."""
    if not flatpak_ver or not system_ver:
        return None
    if Version is None:
        # crude: strip non-version suffix
        def key(v):
            m = re.match(r"v?(\d+(?:\.\d+)*)", v.strip())
            if not m:
                return None
            return tuple(int(x) for x in m.group(1).split("."))
        a, b = key(flatpak_ver), key(system_ver)
        if a is None or b is None:
            return None
        return a >= b
    try:
        # packaging may dislike some distro strings; take leading version-ish
        def pv(v: str):
            v = v.strip()
            # epoch
            if ":" in v:
                v = v.split(":", 1)[1]
            # try full then leading
            try:
                return Version(v)
            except InvalidVersion:
                m = re.match(r"v?(\d+(?:\.\d+)*(?:[\w.~+]*)?)", v)
                if not m:
                    raise
                return Version(m.group(1))
        return pv(flatpak_ver) >= pv(system_ver)
    except Exception:
        return None


def find_match(desktop: dict, by_id: dict, by_name: dict) -> dict | None:
    stem = desktop["desktop_id"]
    if stem in by_id:
        return by_id[stem]
    # firefox.desktop etc. — try org.* containing stem
    # name match
    nn = norm_name(desktop["name"])
    if nn in by_name:
        cands = by_name[nn]
        if len(cands) == 1:
            return cands[0]
        # prefer exact app_id endswith
        for c in cands:
            if c["app_id"].lower().endswith("." + stem.lower().replace(".", "")):
                return c
        return cands[0]
    # tokeny: unique candidate where normalized names equal after removing "desktop"
    return None


def main():
    if not shutil.which("flatpak"):
        print(json.dumps({
            "status": "skip",
            "summary": "flatpak not installed; UI-app Flatpak migration check skipped",
            "evidence": {},
        }))
        return

    desktops = collect_system_desktops()
    catalog = load_flatpak_catalog()
    installed_fp = installed_flatpak_ids()

    by_id = {a["app_id"]: a for a in catalog}
    by_name: dict[str, list] = {}
    for a in catalog:
        by_name.setdefault(norm_name(a["name"]), []).append(a)

    recommend = []
    skipped_reasons = {"already_flatpak": 0, "no_match": 0, "version_lower_or_unknown": 0, "no_system_ver": 0}

    for d in desktops:
        match = find_match(d, by_id, by_name)
        if not match:
            # secondary: app_id equals desktop_id
            skipped_reasons["no_match"] += 1
            continue
        app_id = match["app_id"]
        if app_id in installed_fp:
            skipped_reasons["already_flatpak"] += 1
            continue
        pkg, sys_ver = package_version_for_file(d["path"])
        fp_ver = match.get("version") or ""
        if not sys_ver:
            skipped_reasons["no_system_ver"] += 1
            # cannot prove flatpak >= system — do not recommend
            continue
        cmp = version_gte(fp_ver, sys_ver)
        if cmp is not True:
            skipped_reasons["version_lower_or_unknown"] += 1
            continue
        recommend.append({
            "name": d["name"],
            "desktop_id": d["desktop_id"],
            "system_package": pkg,
            "system_version": sys_ver,
            "flatpak_id": app_id,
            "flatpak_version": fp_ver,
            "flatpak_remote": match.get("remote"),
        })

    # stable sort
    recommend.sort(key=lambda r: r["name"].lower())

    if recommend:
        status = "warn"
        summary = f"{len(recommend)} system UI app(s) have Flatpak equivalents at >= system version"
    else:
        status = "pass"
        summary = "No Flatpak switch recommendations (or none met version bar)"

    # markdown-ish lines for agents
    table_lines = [
        f"| {r['name']} | {r['system_version']} | {r['flatpak_id']} | {r['flatpak_version']} |"
        for r in recommend[:50]
    ]

    print(json.dumps({
        "status": status,
        "summary": summary,
        "evidence": {
            "system_ui_desktops_scanned": len(desktops),
            "flatpak_catalog_size": len(catalog),
            "installed_flatpak_apps": len(installed_fp),
            "skipped": skipped_reasons,
            "recommend_switch": recommend[:50],
            "recommend_switch_truncated": len(recommend) > 50,
            "table_markdown_rows": table_lines,
        },
        "fix_hint": (
            "For chosen apps: flatpak install --user <remote> <flatpak_id>. "
            "Do not migrate DE/system components. Re-run this check after installs."
        ),
    }))


main()
PY

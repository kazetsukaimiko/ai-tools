---
id: desktop.flatpak.apps
title: Prefer Flatpak for desktop UI apps when newer/equal
severity: low
tags: [desktop, flatpak, install-vector]
greenlist: false
platforms: [linux]
install_vectors: [flatpak, system]
requires_elevation_to_fix: false
check: check.sh
---

## Why

For GUI apps, Flatpak often gives better isolation, portable install vectors, and app-centric updates. This item scans **system** `.desktop` launchers, finds Flathub (or other configured remote) equivalents, and lists apps worth **switching** to Flatpak.

**Never recommend a Flatpak that is older than the installed system package.**

## How to check (agent)

Run `check.sh` (may take a few seconds: one `flatpak remote-ls` plus local desktop scan).

- If `flatpak` is **not** installed → **`skip`**.
- Status **`pass`** if there are no switch recommendations.
- Status **`warn`** if the `recommend_switch` table is non-empty (not a hard fail).

Evidence includes a table-friendly list: system app, versions, flatpak id.

## How to fix (agent)

For each recommended row (user picks which):

1. `flatpak install --user <remote> <app_id>` (prefer user install).
2. Confirm the Flatpak appears in the app menu; optionally hide or remove the system package **only if the user wants**.
3. Re-run this check.

Do not mass-migrate without consent. Do not switch OS/DE components, drivers, or pure CLI tools.

## Notes

- Already-exported Flatpak `.desktop` files are ignored as sources.
- Matching is best-effort (desktop id / app name). False positives possible; review before installing.
- Version compare uses packaging-style parsing; if either version is missing/unparseable, the app is **not** recommended (cannot prove Flatpak ≥ system).

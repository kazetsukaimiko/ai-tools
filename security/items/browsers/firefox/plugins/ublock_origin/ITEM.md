---
id: browsers.firefox.plugins.ublock_origin
title: Firefox — uBlock Origin
severity: medium
tags: [browser, greenlist, privacy, ads]
greenlist: true
platforms: [linux]
install_vectors: [system-firefox, flatpak-firefox]
requires_elevation_to_fix: false
agent_remediation: "guide AMO install in correct Firefox; cannot fully automate extension install"
check: check.sh
---

## Why

uBlock Origin is a widely recommended content blocker for reducing tracking and drive-by junk. This group treats it as a **greenlist** extension **when Firefox is installed**.

## How to check (agent)

Run `check.sh`.

- If Firefox is **not** installed (no system `firefox` binary and no Flatpak `org.mozilla.firefox`) → **`skip`**. Do not scan leftover profiles alone.
- If Firefox is installed → scan profiles for extension id `uBlock0@raymondhill.net` under system and Flatpak profile paths.

## How to fix (agent)

Only when Firefox is installed and the user wants this control:

1. Install uBlock Origin from [Mozilla AMO](https://addons.mozilla.org/firefox/addon/ublock-origin/) in the Firefox instance they use (system vs Flatpak are separate).
2. Re-run `check.sh`.

Do **not** recommend installing Firefox solely to satisfy this item (browser choice is personal; this checklist uses **negative** browser recommendations elsewhere, not “you should use Firefox”).

## Notes

- Other Chromium-based browsers need their own items if desired.
- Fake “uBlock” clones exist on some stores — stick to official AMO / known id.

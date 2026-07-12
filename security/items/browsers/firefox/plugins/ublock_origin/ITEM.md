---
id: browsers.firefox.plugins.ublock_origin
title: Firefox — uBlock Origin
severity: medium
tags: [browser, greenlist, privacy, ads]
greenlist: true
platforms: [linux]
install_vectors: [system-firefox, flatpak-firefox]
requires_elevation_to_fix: false
check: check.sh
---

## Why

uBlock Origin is a widely recommended content blocker for reducing tracking and drive-by junk. This group treats it as a **greenlist** extension when Firefox is in use.

## How to check (agent)

Run `check.sh`. It scans Firefox profiles for the extension id `uBlock0@raymondhill.net` under:

- `~/.mozilla/firefox/*/extensions.json` (and `addons.json` fallback)
- Flatpak: `~/.var/app/org.mozilla.firefox/.mozilla/firefox/*/…`

If Firefox is not installed → `skip`. If profiles exist but detection is inconclusive → `warn`.

## How to fix (agent)

1. Confirm the user uses Firefox (system and/or Flatpak).
2. Guide install from [Mozilla AMO — uBlock Origin](https://addons.mozilla.org/firefox/addon/ublock-origin/) in the correct Firefox instance (Flatpak vs system are separate).
3. Re-run `check.sh`. Do not deploy enterprise policies unless asked.

## Notes

- Other Chromium-based browsers need their own items.
- Fake “uBlock” clones exist on some stores — stick to official AMO / known id.

---
id: browsers.firefox.installed
title: Firefox is installed
severity: info
tags: [browser]
greenlist: false
platforms: [linux]
install_vectors: [system-firefox, flatpak-firefox]
requires_elevation_to_fix: true
check: check.sh
---

## Why

Many checklist items target Firefox (extensions, profiles). Knowing whether Firefox exists and **how** it is installed (distro package vs Flatpak) avoids false negatives on later checks.

## How to check (agent)

Run `check.sh`. Expect `pass` if either a `firefox` binary is on PATH or Flatpak app `org.mozilla.firefox` is installed. `warn` if only a partial signal is found.

## How to fix (agent)

Only if the user wants Firefox:

- Distro package via `pkexec` + package manager, or
- `flatpak install flathub org.mozilla.firefox`

Do not replace the user’s preferred browser without asking.

## Notes

Brave / Chromium / Ungoogled Chromium are out of scope for this item (add separate items later).

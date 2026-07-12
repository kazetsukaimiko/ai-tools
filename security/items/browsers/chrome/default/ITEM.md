---
id: browsers.chrome.default
title: Google Chrome / Chromium is not the default browser
severity: medium
tags: [browser, greenlist, privacy, degoogle]
greenlist: true
platforms: [linux]
install_vectors: [google-chrome, chromium, flatpak]
requires_elevation_to_fix: false
agent_remediation: "guide default-browser change; user confirms target (no brand push except ungoogled OK)"
check: check.sh
---

## Why

Stock **Google Chrome** and typical distro **Chromium** builds phone home / integrate with Google services more than this group wants for a **default** browser. Having them installed is not automatically a fail; making them the **system default** is.

## How to check (agent)

Run `check.sh`.

| Situation | Status |
|-----------|--------|
| Default browser is Google Chrome or stock Chromium | **`fail`** (greenlist gap) |
| Default is Ungoogled Chromium (or other non-Google default) | **`pass`** even if Chrome/Chromium is also installed |
| Chrome/Chromium installed but not default | **`pass`** (optional `warn` note in evidence only — do not fail) |
| Cannot determine default | **`warn`** / **`skip`** |

**Ungoogled Chromium** counts as acceptable when a Chromium-based browser is needed — do not flag it as Google Chrome.

## How to fix (agent)

1. Tell the user their default is stock Chrome/Chromium.
2. Help them change the default via desktop settings / `xdg-settings set default-web-browser …` **only for a target they choose**.
3. **Do not positively recommend** Firefox, Brave, or any other browser by name. Allowed guidance:
   - Stop using Google Chrome / stock Chromium as the default.
   - If they want a Chromium-based browser, **Ungoogled Chromium** is an acceptable option this checklist does not flag.
4. Re-run `check.sh`.

## Notes

- This item is intentionally **negative-only** for brand recommendations (except acknowledging Ungoogled Chromium as non-flagged).
- Flatpak app ids vary; checker uses desktop-file / known id heuristics.

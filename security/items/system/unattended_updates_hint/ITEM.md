---
id: system.unattended_updates_hint
title: Automatic security updates (guidance)
severity: low
tags: [system, updates, advisory]
greenlist: false
platforms: [linux]
install_vectors: [distro]
requires_elevation_to_fix: true
---

## Why

Unpatched desktops are a common footgun. Distros differ (`unattended-upgrades`, `dnf-automatic`, pacman hooks, Discover/GNOME Software, etc.), so this item is **guidance** rather than a single hard check.

## How to check (agent)

1. Identify package manager from inventory.
2. Look for known auto-update mechanisms (best effort):
   - Debian/Ubuntu: `unattended-upgrades` package / config under `/etc/apt/apt.conf.d/`
   - Fedora: `dnf-automatic`
   - Arch/derivatives: document that automatic upgrades are uncommon; user may rely on manual + notifications
3. Status: `pass` only with high confidence; otherwise `warn` or `skip` with notes.

No `check.sh` in v1 — agent judgment.

## How to fix (agent)

Recommend the distro’s supported automatic security-update path. Enable only with consent. Prefer official docs over random blog scripts.

## Notes

“Always latest packages” ≠ always safer on rolling releases; focus on security updates when the distro separates them.

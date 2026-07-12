---
id: mail.proton_hint
title: Private mail posture (Proton / similar)
severity: info
tags: [mail, privacy, advisory]
greenlist: false
platforms: [linux]
install_vectors: [proton-bridge, webmail, thunderbird]
requires_elevation_to_fix: false
---

## Why

The group moved toward privacy-oriented mail (e.g. Proton). Local signals vary: Bridge, browser-only, Thunderbird + Bridge, etc. This item is a **conversation prompt**, not a hard fail.

## How to check (agent)

Best effort:

- Binaries / Flatpaks: `protonmail-bridge`, `proton-bridge`, related Flatpak ids
- User confirmation: do they still use a surveillance-friendly webmail as primary?

Status guidance: `pass` if Bridge/client found; `warn` if unclear; `skip` if user says mail is out of scope.

## How to fix (agent)

Only with intent: help install Proton Bridge or configure their preferred client. Never handle mail passwords in shell history if avoidable; prefer official installers/docs.

## Notes

Do not commit addresses or account identifiers into the repo or audit files under git.

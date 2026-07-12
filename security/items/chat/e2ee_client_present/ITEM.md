---
id: chat.e2ee_client_present
title: E2EE chat client is present
severity: medium
tags: [chat, greenlist, privacy, e2ee]
greenlist: true
platforms: [linux]
install_vectors: [element, signal, flatpak]
requires_elevation_to_fix: false
check: check.sh
---

## Why

This group standardized on E2EE chat (e.g. Element / Matrix, Signal) instead of mainstream non-E2EE messengers. Having a real client installed is a greenlist hygiene check — not proof of correct room verification habits.

## How to check (agent)

Run `check.sh`. Looks for Element / Signal binaries or Flatpak apps.

## How to fix (agent)

Help install Element Desktop or Signal (distro package or Flatpak) per user preference. Do not migrate contacts automatically.

## Notes

Web-only Element in a browser will not pass this check — that is intentional for a desktop client footprint.

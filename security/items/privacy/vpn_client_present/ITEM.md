---
id: privacy.vpn_client_present
title: VPN client tooling is present
severity: info
tags: [privacy, vpn]
greenlist: false
platforms: [linux]
install_vectors: [wireguard, networkmanager, vendor-vpn]
requires_elevation_to_fix: true
check: check.sh
---

## Why

This group has used VPNs as part of a privacy pass. Presence of **client tooling** (WireGuard, NetworkManager VPN plugins, vendor apps) is a soft signal — not proof that a VPN is always on.

## How to check (agent)

Run `check.sh`. `pass` if common tools/apps are found; `fail` is **not** used as a hard security fail (status will be `warn` if nothing found) so audits do not shame offline-only hosts.

## How to fix (agent)

Only if the user wants a VPN: help install WireGuard or their provider’s Linux/Flatpak client. Discuss kill-switch / always-on separately (future items).

## Notes

Do not store VPN private keys or account IDs in the repo or in committed reports.

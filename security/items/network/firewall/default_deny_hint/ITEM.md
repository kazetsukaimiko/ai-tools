---
id: network.firewall.default_deny_hint
title: Firewall default-deny posture (advisory)
severity: low
tags: [network, firewall, advisory]
greenlist: false
platforms: [linux]
install_vectors: [firewalld, ufw, nftables]
requires_elevation_to_fix: true
agent_remediation: "advisory + guided review of rules; elevate only if user wants listing/changes"
check: check.sh
---

## Why

Tools being installed is not enough; **inbound default deny** (with explicit allows) is the usual desktop-safe posture. Full policy review is hard to automate portably, so this item is **advisory**.

## How to check (agent)

Run `check.sh` for best-effort signals. Often returns `skip` or `warn` unless a high-confidence signal exists (e.g. ufw status reports default deny). Prefer manual review with the user for nftables.

## How to fix (agent)

Walk the user through their stack’s recommended desktop profile. Use `pkexec` for privileged changes. Re-check only what you can verify.

## Notes

Do not claim “secure” from this item alone.

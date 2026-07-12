---
id: network.firewall.present
title: Host firewall stack is present
severity: medium
tags: [network, greenlist, firewall]
greenlist: true
platforms: [linux]
install_vectors: [firewalld, ufw, nftables, iptables]
requires_elevation_to_fix: true
agent_remediation: "pkexec enable/configure firewall stack after user chooses policy; no surprise rules"
check: check.sh
---

## Why

A host firewall reduces exposure from unexpected listening services and hostile LAN peers. This item only asks whether a known firewall **stack** is available/active — not whether policy is perfect.

## How to check (agent)

Run `check.sh`. `pass` if firewalld/ufw is active, or nft/iptables tooling is present with signs of a ruleset tool. `warn` if tools exist but service inactive. `fail` if nothing usable is found.

## How to fix (agent)

Discuss with the user first (desktop vs laptop, LAN trust). Examples (distro-dependent):

- Enable and configure `firewalld` or `ufw` via `pkexec` / systemctl as appropriate
- Or maintain an `nftables` ruleset the user understands

Do **not** apply a random “lockdown” ruleset without consent. Never open the world to fix an app.

## Notes

Listing full rules often needs elevation. Summarize stack identity before dumping rules.

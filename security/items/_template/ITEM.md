---
id: area.example.control
title: Example control
severity: low
tags: [example]
greenlist: false
platforms: [linux]
install_vectors: []
requires_elevation_to_fix: false
agent_remediation: "describe what the agent can do after approval (or advisory only)"
check: check.sh
---

## Why

Explain the risk this control reduces. Keep it short and portable.

## How to check (agent)

If `check.sh` exists, run it and trust its JSON `status` unless evidence is clearly stale.
Otherwise describe manual checks (commands, UI paths). Cover Flatpak vs system if relevant.

## How to fix (agent)

Step-by-step remediation. Ask the user before changes. Use `pkexec` for elevation (never lead with classic elevators). Prefer user-level fixes when possible.

## Notes

False positives, limits, related items.

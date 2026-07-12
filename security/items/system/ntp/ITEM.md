---
id: system.ntp.synchronized
title: System clock synchronized (NTP)
severity: medium
tags: [system, greenlist, time]
greenlist: true
platforms: [linux]
install_vectors: [systemd-timesyncd, chrony, ntpd]
requires_elevation_to_fix: true
check: check.sh
---

## Why

Correct time matters for TLS, logs, and 2FA. Desktops should use NTP (often `systemd-timesyncd` or chrony).

## How to check (agent)

Run `check.sh` (`timedatectl` when available). `pass` if synchronized; `fail` if explicitly not; `warn`/`skip` if unknown.

## How to fix (agent)

Enable and start the distro’s time sync service via `pkexec`/`systemctl` as appropriate (e.g. `systemd-timesyncd`, `chronyd`). Confirm with `timedatectl`.

## Notes

Path name is `system/ntp` rather than only systemd — multiple implementations exist.

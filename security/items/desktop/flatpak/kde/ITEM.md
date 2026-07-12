---
id: desktop.flatpak.kde
title: KDE Flatpak integration / permissions packages
severity: medium
tags: [desktop, flatpak, kde, greenlist]
greenlist: true
platforms: [linux]
install_vectors: [system]
requires_elevation_to_fix: true
check: check.sh
---

## Why

On KDE Plasma, Flatpak apps need the desktop portal stack so file pickers, screenshots, notifications, and **permission prompts** work. The **Flatpak Permissions** System Settings module (`flatpak-kcm`) lets users review app permissions without the CLI.

## How to check (agent)

Run `check.sh`.

- If `flatpak` is not installed → **`skip`**.
- If the session does not look like KDE/Plasma → **`skip`**.
- Otherwise require (when the distro provides them):
  - `xdg-desktop-portal`
  - `xdg-desktop-portal-kde`
  - `flatpak-kcm` (Flatpak Permissions KCM)

Missing packages → **`fail`** (greenlist gap on KDE + Flatpak hosts).

## How to fix (agent)

Install missing packages with the distro package manager via **`pkexec`** (e.g. `pkexec pacman -S …`, `pkexec apt install …`). Names may vary slightly by distro; search the repos if exact names differ. Re-run the check. Log out/in if portals were newly installed.

## Notes

This is about **host integration packages**, not Flatpak runtimes. Non-KDE desktops should use their own portal backend items later (GNOME: `xdg-desktop-portal-gnome`, etc.).

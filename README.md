# Dark Operator V2 — Rebuilt Installer

This package replaces the broken first V2 installer.

## What V2 does

- Persistent top Operator Bar:
  - `SYS`
  - `STN 1` through `STN 5`
  - active window title
  - tray / network / volume / battery / time / power
- Separate bottom-center shortcut dock
- Dock auto-hides and returns from the bottom edge
- No global Waybar application taskbar
- Five Stations map directly to Hyprland workspaces 1-5
- Dark Operator GTK/KDE foundation
- Existing live configuration is backed up before replacement

## Install

From the repository/package directory:

```bash
chmod +x install.sh
./install.sh
```

The installer is intentionally self-verifying. It will stop with an error if any
required V2 file fails to install.

## Re-running

The installer is safe to run again. Each run makes a new timestamped backup and
replaces the V2-managed files deterministically.

## Diagnostic

After installation:

```bash
./doctor.sh
```

Expected result: `DARK OPERATOR V2: HEALTHY`

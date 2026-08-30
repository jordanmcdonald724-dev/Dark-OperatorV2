# Dark Operator — Quickshell Delta Shell Core

This is the live-system hookup of the Dark Operator Quickshell redesign.

## What is wired now

- floating Quick Dock with installed app discovery
- running-app indicators and focus-existing-window behavior
- native launcher/search using DesktopEntries
- Hyprland workspace, active-window and fullscreen awareness through Quickshell only
- PipeWire default output volume and mute controls
- UPower battery percentage and power profiles
- NetworkManager Wi-Fi state and toggle through Quickshell.Networking
- BlueZ Bluetooth state, toggle and connected-device count through Quickshell.Bluetooth
- native StatusNotifier/System Tray items
- Quickshell notification server and floating notifications
- power actions for lock, suspend, reboot and poweroff
- existing floating Development/Gaming Pods
- existing AI shell integration surface

## Scope boundary

This package does not add, replace, patch, source, or edit any Hyprland configuration file or Hyprland key binding. It does not install another bar, dock, helper daemon, or shell service. All new integration is inside the Quickshell UI.

The installer, service file and rollback script are unchanged from the supplied Delta package.

## Install

```bash
chmod +x install.sh rollback.sh
./install.sh
```

## Roll back

```bash
./rollback.sh
```


## Shell Core 1.1 corrective integration
- Corrects UPower percentage scaling and shows AC/charging state.
- Google Chrome dock action resolves the installed Chrome desktop entry first, then uses a runtime-only executable fallback.
- No Hyprland configuration, services, packages, or unrelated system files are changed.


## Shell Core 2
This stage turns the Control Center into a real device surface while preserving the existing system boundary.

Implemented:
- Wi-Fi network list, connect/disconnect, and in-memory PSK prompt on missing secrets.
- Bluetooth scan plus pair/connect/disconnect actions when an adapter exists.
- PipeWire output-device selection in addition to volume/mute.
- MPRIS media information and previous/play-pause/next controls when a player exists.
- Runtime brightness detection/control through brightnessctl when already available on the system; otherwise the control reports unavailable.
- Live CPU, RAM, and generic thermal telemetry.
- Explicit trusted AI bridge seam. It is unbound by default and creates no listener, socket, shell execution path, or elevated access.

Unchanged boundary:
- No Hyprland configuration changes.
- No package installation.
- No new daemon/service.
- No Waybar or secondary dock.
- Existing install.sh, rollback.sh, and systemd user service remain unchanged.

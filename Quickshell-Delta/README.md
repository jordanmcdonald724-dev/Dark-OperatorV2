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

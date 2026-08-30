# Dark Operator — Quickshell Redesign

This package is a Quickshell-only redesign of the supplied Dark Operator Alpha.

It contains the same five-file package footprint as the Alpha:
- Quickshell shell UI
- existing user service file
- existing installer
- existing rollback script
- this README

## Shell layout

- no permanent full-width toolbar
- compact floating bottom Quick Dock
- built-in application search/launcher
- floating Development and Gaming shortcut pods on an empty desktop
- top-edge reveal System Strip
- General / Development / AI Lab / Gaming shell profiles
- AI shell surface reserved for later integration
- shell chrome hides automatically when the current workspace is fullscreen

The shell reads the existing Hyprland session state through Quickshell and retains the original Alpha's workspace-dispatch behavior where the shell's workspace buttons are clicked.

**This package does not add, replace, patch, source, or edit any Hyprland configuration file or Hyprland key binding.**

## Install

```bash
chmod +x install.sh rollback.sh
./install.sh
```

The installer is the original Alpha installer. It installs only the Quickshell config and its existing user service, keeps the old Waybar/nwg configuration on disk, and restores those visible shell services if Quickshell fails to stay active.

## Roll back

```bash
./rollback.sh
```

# Dark Operator V2

V2 separates the shell into:
- a persistent Operator Bar with SYS, five clickable Stations, and system status
- an auto-hiding bottom shortcut dock

Stations map directly to Hyprland workspaces 1-5. The old global Waybar taskbar is removed.

Install:
```bash
git clone https://github.com/jordanmcdonald724-dev/Dark-OperatorV2.git
cd Dark-OperatorV2
chmod +x install.sh
./install.sh
```

The installer backs up every configuration path it replaces under
`~/.config/dark-operator-v2-backup-YYYYMMDD-HHMMSS/`.

Right-click a running app in the bottom dock to pin/unpin it.

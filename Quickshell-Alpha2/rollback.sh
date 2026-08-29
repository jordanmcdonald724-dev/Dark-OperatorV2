#!/usr/bin/env bash
set -Eeuo pipefail

NEW_SERVICE="dark-operator-quickshell-alpha2.service"
OLD_SERVICE="dark-operator-quickshell.service"

systemctl --user disable --now "$NEW_SERVICE" 2>/dev/null || true

if systemctl --user cat "$OLD_SERVICE" >/dev/null 2>&1; then
  systemctl --user start "$OLD_SERVICE"
  echo "Alpha 2 stopped. Alpha 1 restored."
else
  systemctl --user start waybar.service 2>/dev/null || true
  systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
  echo "Alpha 2 stopped. Previous Waybar/nwg shell restored."
fi

echo "Alpha 2 files were left intact for inspection; no older files were deleted."

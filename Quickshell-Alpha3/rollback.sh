#!/usr/bin/env bash
set -Eeuo pipefail

systemctl --user disable --now dark-operator-quickshell-alpha3.service 2>/dev/null || true

if systemctl --user cat dark-operator-quickshell-alpha2.service >/dev/null 2>&1; then
  systemctl --user start dark-operator-quickshell-alpha2.service
  echo "Alpha 3 stopped. Alpha 2 restored."
elif systemctl --user cat dark-operator-quickshell.service >/dev/null 2>&1; then
  systemctl --user start dark-operator-quickshell.service
  echo "Alpha 3 stopped. Alpha 1 restored."
else
  systemctl --user start waybar.service 2>/dev/null || true
  systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
  echo "Alpha 3 stopped. Previous shell restored."
fi

echo "No older files were overwritten or deleted."

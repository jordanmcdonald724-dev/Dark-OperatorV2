#!/usr/bin/env bash
set -Eeuo pipefail
systemctl --user disable --now dark-operator-quickshell.service 2>/dev/null || true
systemctl --user start waybar.service 2>/dev/null || true
systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
echo "Dark Operator Quickshell stopped; previous Waybar/dock services started when available."

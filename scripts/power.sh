#!/usr/bin/env bash
set -u
menu=$'Lock\nLogout\nReboot\nShutdown'
if ! command -v wofi >/dev/null 2>&1; then
  notify-send "Dark Operator" "Wofi is required for the power menu."
  exit 1
fi
selection="$(printf '%s\n' "$menu" | wofi --dmenu --prompt SYSTEM)"
case "$selection" in
  Lock) if command -v hyprlock >/dev/null 2>&1; then hyprlock; else loginctl lock-session; fi ;;
  Logout) if command -v uwsm >/dev/null 2>&1; then uwsm stop; else hyprctl dispatch exit; fi ;;
  Reboot) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac

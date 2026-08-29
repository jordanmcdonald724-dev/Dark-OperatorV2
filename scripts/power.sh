#!/usr/bin/env bash
set -u

if ! command -v wofi >/dev/null 2>&1; then
  notify-send "Dark Operator" "Wofi is required for the power menu."
  exit 1
fi

selection="$(
  printf '%s\n' Lock Logout Reboot Shutdown |
    wofi --dmenu --prompt SYSTEM
)"

case "$selection" in
  Lock)
    if command -v hyprlock >/dev/null 2>&1; then
      exec hyprlock
    else
      exec loginctl lock-session
    fi
    ;;
  Logout)
    if command -v uwsm >/dev/null 2>&1; then
      exec uwsm stop
    else
      exec hyprctl dispatch exit
    fi
    ;;
  Reboot) exec systemctl reboot ;;
  Shutdown) exec systemctl poweroff ;;
esac

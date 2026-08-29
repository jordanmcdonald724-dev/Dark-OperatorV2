#!/usr/bin/env bash
set -Eeuo pipefail

NAME="dark-operator-alpha3"
SERVICE="dark-operator-quickshell-alpha3.service"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_SYSTEMD="$CFG/systemd/user"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this installer as root."
  exit 1
fi

command -v qs >/dev/null || { echo "Quickshell is not installed."; exit 1; }
command -v hyprctl >/dev/null || { echo "Hyprland/hyprctl is not available."; exit 1; }
[[ -f "$HERE/quickshell/$NAME/shell.qml" ]] || { echo "Package incomplete: shell.qml missing."; exit 1; }
[[ -f "$HERE/$SERVICE" ]] || { echo "Package incomplete: service missing."; exit 1; }

mkdir -p "$CFG/quickshell/$NAME" "$USER_SYSTEMD"

# Alpha 3 is independent. Older Alpha configs/services are never overwritten or deleted.
install -Dm644 "$HERE/quickshell/$NAME/shell.qml" "$CFG/quickshell/$NAME/shell.qml"
install -Dm644 "$HERE/$SERVICE" "$USER_SYSTEMD/$SERVICE"

systemctl --user daemon-reload
systemctl --user enable "$SERVICE" >/dev/null

# Stop visible predecessors only. Their files remain intact.
systemctl --user stop dark-operator-quickshell-alpha2.service 2>/dev/null || true
systemctl --user stop dark-operator-quickshell.service 2>/dev/null || true
systemctl --user stop waybar.service 2>/dev/null || true
systemctl --user stop nwg-dock-hyprland.service 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
pkill -x nwg-dock-hyprland 2>/dev/null || true

systemctl --user restart "$SERVICE"
sleep 2

if ! systemctl --user is-active --quiet "$SERVICE"; then
  echo
  echo "ALPHA 3 FAILED TO START. Restoring Alpha 2..."
  systemctl --user stop "$SERVICE" 2>/dev/null || true

  if systemctl --user cat dark-operator-quickshell-alpha2.service >/dev/null 2>&1; then
    systemctl --user start dark-operator-quickshell-alpha2.service 2>/dev/null || true
  elif systemctl --user cat dark-operator-quickshell.service >/dev/null 2>&1; then
    systemctl --user start dark-operator-quickshell.service 2>/dev/null || true
  else
    systemctl --user start waybar.service 2>/dev/null || true
    systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
  fi

  journalctl --user -u "$SERVICE" -n 60 --no-pager || true
  exit 1
fi

echo
echo "DARK OPERATOR QUICKSHELL ALPHA 3 INSTALLED"
echo "Service: $SERVICE"
echo "Config: $CFG/quickshell/$NAME/shell.qml"
echo "Older Alpha builds remain intact."
echo "Rollback: $HERE/rollback.sh"

#!/usr/bin/env bash
set -Eeuo pipefail

NAME="dark-operator-alpha2"
SERVICE="dark-operator-quickshell-alpha2.service"
OLD_SERVICE="dark-operator-quickshell.service"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_SYSTEMD="$CFG/systemd/user"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this installer as root."
  exit 1
fi

command -v qs >/dev/null || { echo "Quickshell is not installed."; exit 1; }
command -v hyprctl >/dev/null || { echo "Hyprland/hyprctl is not available."; exit 1; }
[[ -f "$HERE/quickshell/$NAME/shell.qml" ]] || { echo "Package is incomplete: shell.qml missing."; exit 1; }
[[ -f "$HERE/$SERVICE" ]] || { echo "Package is incomplete: service file missing."; exit 1; }

mkdir -p "$CFG/quickshell/$NAME" "$USER_SYSTEMD"

# New generation only. Do not overwrite or delete Alpha 1.
install -Dm644 "$HERE/quickshell/$NAME/shell.qml" "$CFG/quickshell/$NAME/shell.qml"
install -Dm644 "$HERE/$SERVICE" "$USER_SYSTEMD/$SERVICE"

systemctl --user daemon-reload
systemctl --user enable "$SERVICE" >/dev/null

# Stop the previous shell instance, but leave every old file/config intact.
systemctl --user stop "$OLD_SERVICE" 2>/dev/null || true
systemctl --user stop waybar.service 2>/dev/null || true
systemctl --user stop nwg-dock-hyprland.service 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
pkill -x nwg-dock-hyprland 2>/dev/null || true

systemctl --user restart "$SERVICE"
sleep 2

if ! systemctl --user is-active --quiet "$SERVICE"; then
  echo
  echo "Alpha 2 failed to stay active. Restoring Alpha 1 if available..."
  systemctl --user stop "$SERVICE" 2>/dev/null || true

  if systemctl --user cat "$OLD_SERVICE" >/dev/null 2>&1; then
    systemctl --user start "$OLD_SERVICE" 2>/dev/null || true
  else
    systemctl --user start waybar.service 2>/dev/null || true
    systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
  fi

  echo "----- Alpha 2 Quickshell log -----"
  journalctl --user -u "$SERVICE" -n 50 --no-pager || true
  exit 1
fi

echo
echo "DARK OPERATOR QUICKSHELL ALPHA 2 INSTALLED"
echo "Config: $CFG/quickshell/$NAME/shell.qml"
echo "Service: $SERVICE active"
echo
echo "Alpha 1 files were NOT overwritten."
echo "Rollback command:"
echo "  $HERE/rollback.sh"

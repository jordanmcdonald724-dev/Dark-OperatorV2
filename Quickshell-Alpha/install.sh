#!/usr/bin/env bash
set -Eeuo pipefail

NAME="dark-operator"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_SYSTEMD="$CFG/systemd/user"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CFG/dark-operator-quickshell-backup-$STAMP"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this installer as root."
  exit 1
fi

command -v qs >/dev/null || { echo "Quickshell is not installed."; exit 1; }
command -v hyprctl >/dev/null || { echo "Hyprland/hyprctl is not available."; exit 1; }
[[ -f "$HERE/quickshell/$NAME/shell.qml" ]] || { echo "Package is incomplete: shell.qml missing."; exit 1; }

mkdir -p "$BACKUP" "$CFG/quickshell" "$USER_SYSTEMD"

# Preserve whatever is currently running/configured. Nothing is destroyed.
[[ -d "$CFG/quickshell/$NAME" ]] && cp -a "$CFG/quickshell/$NAME" "$BACKUP/" || true
[[ -f "$USER_SYSTEMD/dark-operator-quickshell.service" ]] && cp -a "$USER_SYSTEMD/dark-operator-quickshell.service" "$BACKUP/" || true

install -Dm644 "$HERE/quickshell/$NAME/shell.qml" "$CFG/quickshell/$NAME/shell.qml"
install -Dm644 "$HERE/dark-operator-quickshell.service" "$USER_SYSTEMD/dark-operator-quickshell.service"

systemctl --user daemon-reload
systemctl --user enable dark-operator-quickshell.service >/dev/null

# Stop only the old visible shell pieces. They remain installed and can be restored.
systemctl --user stop waybar.service 2>/dev/null || true
systemctl --user stop nwg-dock-hyprland.service 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
pkill -x nwg-dock-hyprland 2>/dev/null || true

systemctl --user restart dark-operator-quickshell.service
sleep 2

if ! systemctl --user is-active --quiet dark-operator-quickshell.service; then
  echo
  echo "Quickshell failed to stay active. Restoring old shell services..."
  systemctl --user start waybar.service 2>/dev/null || true
  systemctl --user start nwg-dock-hyprland.service 2>/dev/null || true
  echo "----- Quickshell log -----"
  journalctl --user -u dark-operator-quickshell.service -n 40 --no-pager || true
  exit 1
fi

echo
echo "DARK OPERATOR QUICKSHELL ALPHA INSTALLED"
echo "Config: $CFG/quickshell/$NAME/shell.qml"
echo "Backup: $BACKUP"
echo "Service: active"
echo
echo "Rollback command:"
echo "  $HERE/rollback.sh"

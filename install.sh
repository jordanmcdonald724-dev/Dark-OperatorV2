#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${BASE}/dark-operator-v2-backup-${STAMP}"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "Dark Operator V2"
echo "================"
echo

for cmd in waybar hyprctl systemctl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd"; exit 1; }
done

echo "Installing official Arch dependencies..."
sudo pacman -S --needed nwg-dock-hyprland adw-gtk-theme papirus-icon-theme

mkdir -p "$BACKUP"

backup_path() {
  local path="$1"
  [[ -e "$path" ]] && cp -a "$path" "$BACKUP/"
}

backup_path "${BASE}/waybar"
backup_path "${BASE}/dark-operator-v2"
backup_path "${BASE}/nwg-dock-hyprland"
backup_path "${BASE}/gtk-3.0"
backup_path "${BASE}/gtk-4.0"
backup_path "${BASE}/kdeglobals"

mkdir -p "${BASE}/waybar"
mkdir -p "${BASE}/dark-operator-v2/scripts"
mkdir -p "${BASE}/nwg-dock-hyprland"
mkdir -p "${BASE}/gtk-3.0" "${BASE}/gtk-4.0"
mkdir -p "${HOME}/.local/share/color-schemes"
mkdir -p "${BASE}/systemd/user"

cp "${HERE}/waybar/config.jsonc" "${BASE}/waybar/config.jsonc"
cp "${HERE}/waybar/style.css" "${BASE}/waybar/style.css"
cp "${HERE}/scripts/"*.sh "${BASE}/dark-operator-v2/scripts/"
chmod +x "${BASE}/dark-operator-v2/scripts/"*.sh

cp "${HERE}/dock/style.css" "${BASE}/nwg-dock-hyprland/style.css"
cp "${HERE}/theme/gtk-settings.ini" "${BASE}/gtk-3.0/settings.ini"
cp "${HERE}/theme/gtk-settings.ini" "${BASE}/gtk-4.0/settings.ini"
cp "${HERE}/theme/DarkOperator.colors" "${HOME}/.local/share/color-schemes/DarkOperator.colors"

cat > "${BASE}/kdeglobals" <<'EOF'
[General]
ColorScheme=DarkOperator
[Icons]
Theme=Papirus-Dark
[KDE]
widgetStyle=Breeze
EOF

if [[ ! -s "${HOME}/.cache/nwg-dock-pinned" ]]; then
  mkdir -p "${HOME}/.cache"
  cat > "${HOME}/.cache/nwg-dock-pinned" <<'EOF'
google-chrome
org.kde.dolphin
code
kitty
EOF
fi

cp "${HERE}/systemd/dark-operator-dock.service" "${BASE}/systemd/user/dark-operator-dock.service"

systemctl --user daemon-reload
systemctl --user enable --now waybar.service
systemctl --user restart waybar.service

systemctl --user disable --now dark-operator-dock.service >/dev/null 2>&1 || true
pkill -x nwg-dock-hyprla >/dev/null 2>&1 || true
systemctl --user enable --now dark-operator-dock.service

echo
echo "Dark Operator V2 installed."
echo "Backup: $BACKUP"
echo "Operator Bar: top / persistent"
echo "Shortcut Dock: bottom / auto-hide"
echo "Stations: STN 1-5"
echo
echo "Close and reopen GTK/Qt apps to pick up the new theme."

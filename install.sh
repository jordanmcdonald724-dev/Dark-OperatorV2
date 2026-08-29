#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo; echo "DARK OPERATOR V2 INSTALL FAILED at line $LINENO"; exit 1' ERR

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG="${HOME}/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${CFG}/dark-operator-backup-${STAMP}"

[[ "${EUID}" -ne 0 ]] || { echo "Run as your normal user, not root."; exit 1; }

required=(
  waybar/config.jsonc waybar/style.css dock/style.css
  scripts/launcher.sh scripts/power.sh scripts/station-status.sh
  theme/gtk-settings.ini theme/DarkOperator.colors
  systemd/dark-operator-dock.service doctor.sh
)
for rel in "${required[@]}"; do
  [[ -f "${HERE}/${rel}" ]] || { echo "Package missing ${rel}"; exit 1; }
done

echo "Dark Operator V2"
echo "================"
echo "[1/8] Dependencies"
sudo pacman -S --needed nwg-dock-hyprland adw-gtk-theme papirus-icon-theme

echo "[2/8] Backup"
mkdir -p "$BACKUP"
for path in \
  "${CFG}/waybar" \
  "${CFG}/dark-operator-v2" \
  "${CFG}/nwg-dock-hyprland" \
  "${CFG}/gtk-3.0" \
  "${CFG}/gtk-4.0" \
  "${CFG}/kdeglobals" \
  "${CFG}/systemd/user/dark-operator-dock.service"
do
  [[ -e "$path" ]] && cp -a "$path" "$BACKUP/"
done

echo "[3/8] Remove obsolete/broken V2-managed state"
# These are artifacts of the failed V2 attempt only.
rm -rf "${HOME}/config/dark-operator-v2"
rm -rf "${CFG}/dark-operator-v2/scipts"
rm -rf "${CFG}/dark-operator-v2"
rm -rf "${CFG}/nwg-dock-hyprland"

# Replace Waybar's V2-managed live config, but do not touch Hyprland or V1 repo.
mkdir -p "${CFG}/waybar"
rm -f "${CFG}/waybar/config" "${CFG}/waybar/config.json" "${CFG}/waybar/config.jsonc" "${CFG}/waybar/style.css"

echo "[4/8] Operator Bar"
install -Dm0644 "${HERE}/waybar/config.jsonc" "${CFG}/waybar/config.jsonc"
install -Dm0644 "${HERE}/waybar/style.css" "${CFG}/waybar/style.css"
install -Dm0755 "${HERE}/scripts/launcher.sh" "${CFG}/dark-operator-v2/scripts/launcher.sh"
install -Dm0755 "${HERE}/scripts/power.sh" "${CFG}/dark-operator-v2/scripts/power.sh"
install -Dm0755 "${HERE}/scripts/station-status.sh" "${CFG}/dark-operator-v2/scripts/station-status.sh"

echo "[5/8] Shortcut Dock"
install -Dm0644 "${HERE}/dock/style.css" "${CFG}/nwg-dock-hyprland/style.css"
mkdir -p "${HOME}/.cache"
if [[ ! -s "${HOME}/.cache/nwg-dock-pinned" ]]; then
  printf '%s\n' google-chrome org.kde.dolphin code kitty > "${HOME}/.cache/nwg-dock-pinned"
fi

echo "[6/8] Application theme"
install -Dm0644 "${HERE}/theme/gtk-settings.ini" "${CFG}/gtk-3.0/settings.ini"
install -Dm0644 "${HERE}/theme/gtk-settings.ini" "${CFG}/gtk-4.0/settings.ini"
install -Dm0644 "${HERE}/theme/DarkOperator.colors" "${HOME}/.local/share/color-schemes/DarkOperator.colors"
cat > "${CFG}/kdeglobals" <<'EOF'
[General]
ColorScheme=DarkOperator
[Icons]
Theme=Papirus-Dark
[KDE]
widgetStyle=Breeze
EOF

echo "[7/8] Services"
install -Dm0644 "${HERE}/systemd/dark-operator-dock.service" "${CFG}/systemd/user/dark-operator-dock.service"
systemctl --user daemon-reload
systemctl --user enable waybar.service >/dev/null
systemctl --user restart waybar.service
pkill -x nwg-dock-hyprla >/dev/null 2>&1 || true
systemctl --user enable dark-operator-dock.service >/dev/null
systemctl --user restart dark-operator-dock.service

echo "[8/8] Verify"
cmp -s "${HERE}/waybar/config.jsonc" "${CFG}/waybar/config.jsonc"
cmp -s "${HERE}/waybar/style.css" "${CFG}/waybar/style.css"
cmp -s "${HERE}/scripts/launcher.sh" "${CFG}/dark-operator-v2/scripts/launcher.sh"
cmp -s "${HERE}/scripts/power.sh" "${CFG}/dark-operator-v2/scripts/power.sh"
cmp -s "${HERE}/scripts/station-status.sh" "${CFG}/dark-operator-v2/scripts/station-status.sh"
[[ ! -e "${HOME}/config/dark-operator-v2" ]]
[[ ! -e "${CFG}/dark-operator-v2/scipts" ]]
systemctl --user is-active --quiet waybar.service
systemctl --user is-active --quiet dark-operator-dock.service

echo
echo "DARK OPERATOR V2 INSTALLED AND VERIFIED"
echo "Rollback backup: ${BACKUP}"

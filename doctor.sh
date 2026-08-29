#!/usr/bin/env bash
set -u
fail=0
ok(){ printf '[OK] %s\n' "$1"; }
bad(){ printf '[FAIL] %s\n' "$1"; fail=1; }

for f in \
 "$HOME/.config/waybar/config.jsonc" \
 "$HOME/.config/waybar/style.css" \
 "$HOME/.config/dark-operator-v2/scripts/launcher.sh" \
 "$HOME/.config/dark-operator-v2/scripts/power.sh" \
 "$HOME/.config/dark-operator-v2/scripts/station-status.sh" \
 "$HOME/.config/nwg-dock-hyprland/style.css" \
 "$HOME/.config/systemd/user/dark-operator-dock.service"
do
  [[ -f "$f" ]] && ok "$f" || bad "missing $f"
done

for f in \
 "$HOME/.config/dark-operator-v2/scripts/launcher.sh" \
 "$HOME/.config/dark-operator-v2/scripts/power.sh" \
 "$HOME/.config/dark-operator-v2/scripts/station-status.sh"
do
  [[ -x "$f" ]] && ok "executable $f" || bad "not executable $f"
done

[[ ! -e "$HOME/config/dark-operator-v2" ]] && ok "no stray ~/config V2 tree" || bad "stray ~/config V2 tree exists"
[[ ! -e "$HOME/.config/dark-operator-v2/scipts" ]] && ok "no misspelled scipts directory" || bad "misspelled scipts directory exists"
grep -q '"position": "top"' "$HOME/.config/waybar/config.jsonc" && ok "V2 top Operator Bar config" || bad "wrong Waybar config"
systemctl --user is-active --quiet waybar.service && ok "waybar.service active" || bad "waybar.service inactive"
systemctl --user is-active --quiet dark-operator-dock.service && ok "dock service active" || bad "dock service inactive"

if (( fail == 0 )); then
  echo; echo "DARK OPERATOR V2: HEALTHY"; exit 0
else
  echo; echo "DARK OPERATOR V2: CHECK FAILED"; exit 1
fi

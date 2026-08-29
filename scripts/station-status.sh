#!/usr/bin/env bash
set -u

station="${1:-1}"
active="$(
  hyprctl activeworkspace -j 2>/dev/null |
    sed -n 's/^[[:space:]]*"id":[[:space:]]*\(-\{0,1\}[0-9]\+\),\{0,1\}[[:space:]]*$/\1/p' |
    head -n 1
)"

if [[ "$active" == "$station" ]]; then
  printf '{"text":"STN %s","class":"active","tooltip":"Station %s — active"}\n' "$station" "$station"
else
  printf '{"text":"STN %s","class":"idle","tooltip":"Switch to Station %s"}\n' "$station" "$station"
fi

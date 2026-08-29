#!/usr/bin/env bash
set -u

if command -v hyprlauncher >/dev/null 2>&1; then
  exec hyprlauncher
fi

if command -v wofi >/dev/null 2>&1; then
  exec wofi --show drun --allow-images
fi

notify-send "Dark Operator" "No application launcher is installed."

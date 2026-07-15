#!/bin/sh
# Skip killactive for windows in the no-kill list (e.g. Stardew Valley)
class=$(hyprctl activewindow -j | jq -r .class)

case "$class" in
    steam_app_413150) exit 0 ;;
esac

hyprctl dispatch killactive

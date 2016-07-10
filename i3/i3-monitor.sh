#!/usr/bin/env bash

MAIN_MONITOR=$(xrandr | grep -w connected | head -n1 | cut -f 1 -d " ")
SEC_MONITOR=$(xrandr | grep -w connected | head -n 2 | tail -n 1 | cut -f 1 -d " ")
CUR_WORKSPACE=$(i3-msg message -t get_workspaces | jq '.[] | select(.focused==true) | .name' 2>/dev/null)

read -r -d '' LIST <<- EOF
	1) Internal
	2) External
	3) Dual
EOF

SELECTION=$(
    echo -e "${LIST}" \
    | rofi -dmenu -auto-select -fullscreen -p "Monitor layout:"
)

case "${SELECTION}" in
    *Internal)
        xrandr  --output "${SEC_MONITOR}" --off \
                --output "${MAIN_MONITOR}" --auto
        ;;
    *External)
        xrandr  --output "${MAIN_MONITOR}" --off \
                --output "${SEC_MONITOR}" --auto
        ;;
    *Dual)
        # sleep is neccesary to not hang X...
        sleep 0.5
        xrandr  --output "${MAIN_MONITOR}" --auto \
                --output "${SEC_MONITOR}" --auto --above "${MAIN_MONITOR}"
        ;;
esac

DISPLAY=:0 feh --bg-scale ~/Pictures/wallpaper.*

if [[ -n "${CUR_WORKSPACE}" ]]; then
    i3-msg workspace "${CUR_WORKSPACE}" &>/dev/null
fi

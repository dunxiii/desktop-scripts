#!/usr/bin/env bash

MAIN_MONITOR=$(xrandr | grep -w connected | head -n1 | cut -f 1 -d " ")
SEC_MONITOR=$(xrandr | grep -w connected | head -n 2 | tail -n 1 | cut -f 1 -d " ")
CUR_WORKSPACE=$(i3-msg message -t get_workspaces | jq '.[] | select(.focused==true) | .name' 2>/dev/null)
LAST_CONFIG=~/.screenlayout/last_config

read -r -d '' LIST <<- EOF
	1) Internal
	2) External
	3) Dual
EOF

main() {
    if [[ "${LOAD_CONF}" = true ]]; then

        if [[ "$(cat "${LAST_CONFIG}" | tail -n +2)" == "$(xrandr | grep -w connected | awk '{print $1,$2}')" ]]; then
            SELECTION=$(cat "${LAST_CONFIG}" | head -n 1 | cut -f 1 -d " ")
            SEC_PLACEMENT=$(cat "${LAST_CONFIG}" | head -n 1 | cut -f 2 -d " ")
        else
            SELECTION="Internal"
        fi

    else

        SELECTION=$(
            echo -e "${LIST}" \
            | rofi -dmenu -auto-select -fullscreen -p "Monitor layout:" \
            | cut -f 2 -d " "
        )

    fi

    case "${SELECTION}" in
        Internal)
            xrandr  --output "${SEC_MONITOR}" --off \
                    --output "${MAIN_MONITOR}" --auto
            ;;
        External)
            xrandr  --output "${MAIN_MONITOR}" --off \
                    --output "${SEC_MONITOR}" --auto
            ;;
        Dual)
            if [[ ! "${LOAD_CONF}" = true ]]; then
                SEC_PLACEMENT=$(
                    echo -e "Above\nBelow\nLeft-of\nRight-of" \
                    | rofi -dmenu -auto-select -fullscreen -p "Placement of second monitor:"
                )
            fi

            [[ -z "${SEC_PLACEMENT}" ]] && exit

            # sleep is neccesary to not hang X...
            sleep 0.5
            xrandr  --output "${MAIN_MONITOR}" --auto \
                    --output "${SEC_MONITOR}" --auto "--${SEC_PLACEMENT,,}" "${MAIN_MONITOR}"
            ;;
    esac

    DISPLAY=:0 feh --bg-scale ~/Pictures/wallpaper.*

    if [[ -n "${CUR_WORKSPACE}" ]]; then
        i3-msg workspace "${CUR_WORKSPACE}" &>/dev/null
    fi

    echo -e "${SELECTION} ${SEC_PLACEMENT}" > "${LAST_CONFIG}"
    echo -e "$(xrandr | grep -w connected | awk '{print $1,$2}')" >> "${LAST_CONFIG}"
}

while getopts "c" option; do
    case ${option} in
        c)
            LOAD_CONF=true
            ;;
    esac
done

main

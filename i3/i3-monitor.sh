#!/usr/bin/env bash

MAIN_MONITOR="eDP1"
SEC_MONITOR=$(xrandr | grep -w -e connected | grep -v -e "${MAIN_MONITOR}" | cut -f 1 -d " ")
CUR_WORKSPACE=$(i3-msg message -t get_workspaces | jq '.[] | select(.focused==true) | .name' 2>/dev/null)
LAST_CONFIG=~/.screenlayout/last_config

read -r -d '' LIST <<- EOF
	1) Internal
	2) External
	3) Dual
EOF

main() {

    if [[ "${LOAD_CONF}" = true ]]; then

        if [[ -f "${LAST_CONFIG}" ]]; then

            source "${LAST_CONFIG}"

            for display in "${MAIN_MONITOR}" "${SEC_MONITOR}"; do
                xrandr | grep -w -e connected | grep -e "${display}"
                err=$?

                # Handle wrong display names and disconncted monitors
                if [[ "${err}" -eq 1 ]] && [[ "${display}" == "${MAIN_MONITOR}" ]]; then
                    exit 1
                elif [[ "${err}" -eq 1 ]] && [[ "${display}" == "${SEC_MONITOR}" ]]; then
                    unset SEC_MONITOR
                    unset SEC_PLACEMENT
                    SELECTION="Internal"
                fi
            done

        fi

    else

        SELECTION=$(
            echo -e "${LIST}" \
            | rofi -dmenu -auto-select -fullscreen -p "Monitor layout:" \
            | cut -f 2 -d " "
        )

    fi

    killall compton

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

            xrandr  --output "${MAIN_MONITOR}" --auto \
                    --output "${SEC_MONITOR}" --auto "--${SEC_PLACEMENT,,}" "${MAIN_MONITOR}"
            ;;
    esac

    compton -b --config ~/.compton.conf

    DISPLAY=:0 feh --bg-scale ~/Pictures/wallpaper.*

    if [[ -n "${CUR_WORKSPACE}" ]]; then
        i3-msg workspace "${CUR_WORKSPACE}" &>/dev/null
    fi

    if [[ ! -d $(dirname "${LAST_CONFIG}") ]]; then
        mkdir $(dirname "${LAST_CONFIG}")
    fi

    echo -e "SELECTION=${SELECTION}" > "${LAST_CONFIG}"
    echo -e "SEC_PLACEMENT=${SEC_PLACEMENT}" >> "${LAST_CONFIG}"
    echo -e "SEC_MONITOR=${SEC_MONITOR}" >> "${LAST_CONFIG}"
}

while getopts "c" option; do
    case ${option} in
        c)
            LOAD_CONF=true
            ;;
    esac
done

main

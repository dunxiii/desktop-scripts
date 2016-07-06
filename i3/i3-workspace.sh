#!/usr/bin/env bash

WORKSPACES=$(
    i3-msg -t get_workspaces \
    | tr ',' '\n' \
    | grep "name" \
    | sed 's/"name":"\(.*\)"/\1/g' \
    | sort -n
)

KEY_COLOR="#268BD2"
set_key_color() {
    echo "<span color='${KEY_COLOR}'>${1}</span>: ${2}&#09;"
}

MENU+="$(set_key_color "Enter" "Go to")"
MENU+="$(set_key_color "Alt+r" "Rename")"
MENU+="$(set_key_color "Alt+m" "Move container")"
MENU+="$(set_key_color "Mod+[hjkl]" "Move workspace")"

main() {
    SELECTION=$(echo "${WORKSPACES}" | rofi -dmenu -p "Workspace:" -mesg "${MENU}" \
        -kb-custom-1 "Alt+r" \
        -kb-custom-2 "Alt+m" \
        -kb-custom-3 "Alt+o" \
        -kb-custom-4 "Super+h" \
        -kb-custom-5 "Super+j" \
        -kb-custom-6 "Super+k" \
        -kb-custom-7 "Super+l")
    ROFI_EXIT=$?

    case "${ROFI_EXIT}" in
        0)
            i3-msg workspace "${SELECTION}"
            ;;
        10)
            i3-msg rename workspace to "${SELECTION/\#/\ }"
            ;;
        11)
            i3-msg move container to workspace "${SELECTION/\#/\ }"
            ;;
        13)
            i3-msg move workspace to output left
            ;;
        14)
            i3-msg move workspace to output down
            ;;
        15)
            i3-msg move workspace to output up
            ;;
        16)
            i3-msg move workspace to output right
            ;;
    esac
}

main
exit

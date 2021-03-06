#!/usr/bin/env bash

# TODO other keybinds for second monitor F1-F12
# TODO Show on all monitors?

WORKSPACES=$(
    i3-msg -t get_workspaces \
    | tr ',' '\n' \
    | grep "name" \
    | sed 's/"name":"\(.*\)"/\1/g' \
    | sort -n
)

find_workspace() {
    # Check if workspace already exists
    WORKSPACE="$(echo -e "${WORKSPACES}" | grep --word-regexp "${1}\|${1}:")"
    if [[ $? -eq 0 ]]; then
        # Return workspace
        echo "${WORKSPACE}"
    else
        # Return number if workspace was not found in list
        echo "${1}"
    fi
}

goto_workspace() {
    # Check if workspace for that key exist
    WORKSPACE="$(find_workspace "${1}")"

    if [[ "${2}" = mv_container ]]; then
        i3-msg move container to workspace "${WORKSPACE}"
    else
        i3-msg workspace "${WORKSPACE}"
    fi
}

# TODO Better rename workflow
# Not used
rename_workspace() {
    NAME=$(rofi -dmenu -p "Name workspace:" <<< "")
    i3-msg rename workspace to "${SELECTION/\#/\ }"
}

#find_free_num() {
#    i=1
#    while true; do
#        grep --quiet --word-regexp Mod4+${i} <<< ${KEYBINDS}
#        [[ $? -ne 0 ]] && break
#        ((i++))
#    done
#    echo ${i}
#}

set_key_color() {
    KEY_COLOR="#268BD2"
    echo "<span color='${KEY_COLOR}'>${1}</span>: ${2}&#09;"
}

main() {
    # Mod4+Tab
    if [[ "$#" -lt 1 ]]; then
        MENU+="$(set_key_color "Enter" "Go to")"
        MENU+="$(set_key_color "Alt+r" "Rename")"
        MENU+="$(set_key_color "Alt+m" "Move container")"

        SELECTION=$(echo "${WORKSPACES}" | rofi -dmenu -p "Workspace:" -mesg "${MENU}" \
            -kb-custom-1 "Alt+r" \
            -kb-custom-2 "Alt+m")
        ROFI_EXIT=$?

        case "${ROFI_EXIT}" in
            0)
                goto_workspace "$(cut -d ":" -f1 <<< "${SELECTION}")"
                ;;
            10)
                i3-msg rename workspace to "${SELECTION/\#/\ }"
                ;;
            11)
                i3-msg move container to workspace "${SELECTION/\#/\ }"
                ;;
        esac
    else
        # Mod4+X or Mod4+Shift+X was pressed
        goto_workspace "$@"
    fi
}

main "$@"
exit

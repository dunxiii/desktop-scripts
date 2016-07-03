#!/usr/bin/env bash

WORKSPACE=$(
    i3-msg -t get_workspaces | \
    tr ',' '\n' | \
    grep "name" | \
    sed 's/"name":"\(.*\)"/\1/g' | \
    sort -n | \
    rofi -dmenu -p "Select workspace:"
    )

if [[ -n "${WORKSPACE}" ]]; then
    i3-msg workspace "${WORKSPACE}"
fi

exit

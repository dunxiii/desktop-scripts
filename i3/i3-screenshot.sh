#!/bin/bash

# List items
list="1) fullscreen
      2) select window"

# Menu to print on screen
# sed string removes leading whitespace only
selection=$(
    echo -e "${list}" \
    | sed -e 's/^[[:space:]]*//' \
    | rofi -dmenu -auto-select -fullscreen -p "Screenshot:"
)

term="terminator --geometry=600x400 -e /bin/zsh -c"

if [ ! -d ~/Pictures/screenshots/ ]; then
    mkdir ~/Pictures/screenshots/
fi

# What to execute
case "${selection}" in
    "1)"*)
        scrot -d 1 '%Y-%m-%d_$wx$h.png' -e 'mv $f ~/Pictures/screenshots/'
        ;;
    "2)"*)
        scrot -s '%Y-%m-%d_$wx$h.png' -e 'mv $f ~/Pictures/screenshots/'
        ;;
    *)
        exit 1
        ;;
esac

exit

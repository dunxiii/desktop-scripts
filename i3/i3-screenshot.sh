#!/bin/bash

# List items
list="1) fullscreen
      2) select window"
DEST_PATH=~/Pictures/screenshots

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

screanshoot() {
    NAME="$(date +%Y%m%d)"
    if ls ${DEST_PATH}/${NAME}*.png 1> /dev/null 2>&1; then
        i=0
        while ls ${DEST_PATH}/${NAME}-${i}.png 1> /dev/null 2>&1; do
            let i++
        done
        NAME="${NAME}-${i}"
    fi

    scrot ${1} "${NAME}.png" -e "mv \$f ${DEST_PATH}/"
}

# What to execute
case "${selection}" in
    "1)"*)
        screanshoot "-d 1"
        ;;
    "2)"*)
        screanshoot "-s"
        ;;
    *)
        exit 1
        ;;
esac

exit

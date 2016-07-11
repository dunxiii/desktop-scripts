#!/bin/bash

# Get user that started the visual environment
user=$(w -sh | grep "tty$(fgconsole 2>/dev/null)" | awk 'NR==1{print $1}')

# If used from cmd directly set user var correctly
if [ -z "${user}" ]
then
    user=${USER}
fi

# List items
list="1) lock
      2) logout
      3) poweroff
      4) reboot
      5) reboot to UEFI
      6) suspend"

# Lock function
lock() {
    pkill gnome-keyring-d || true
    i3lock -ti /home/"${user}"/Pictures/wallpaper.*
}

rofi_menu() {
    # sed string removes leading whitespace only
    selection=$(
    echo -e "${list}" \
        | sed -e 's/^[[:space:]]*//' \
        | rofi -dmenu -auto-select -fullscreen -p "Power option:"
    )
}

# Enable scipt to be used from cli
while getopts ":ls" option; do
    case ${option} in
        l)
            selection="1)"
            ;;
        s)
            selection="6)"
            ;;
        *)
            echo "Provide correct argument, only accepted argument is -s"
            ;;
    esac
done

[ -z "${selection:-}" ] && rofi_menu

# What to execute
case "${selection}" in
    "1)"*)
        lock
        xset dpms force off
        ;;
    "2)"*)
        i3-msg exit
        ;;
    "3)"*)
        systemctl poweroff
        ;;
    "4)"*)
        systemctl reboot
        ;;
    "5)"*)
        systemctl reboot --firmware-setup
        ;;
    "6)"*)
        lock
        systemctl suspend
        ;;
    *)
        exit 1
        ;;
esac

exit

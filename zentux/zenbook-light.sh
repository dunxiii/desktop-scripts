#!/bin/bash

# Contants
readonly pathScree=/sys/class/backlight/intel_backlight
readonly pathKeyboard=/sys/class/leds/asus::kbd_backlight
readonly configFile=~/.zenbook-light

# Sets correct permissions to a system file
# so users can map this script to shortcuts
set_permission() {

    # Make sure the file have been created
    # This is needed if run as a service at boot, to be sure the file exist before we do anything
    while [ ! -f ${path}/brightness ]
    do
        sleep 1s
    done

    if [ ${UID} -eq 0 ]; then
        chmod o+w ${path}/brightness
    else
        echo "You don't have the right permissions to change permission" >&2
        exit 1
    fi
}

# This funtion change the brightness
set_brightness() {

    # Controll if the current user has write permission to the system file
    if [ ! -w ${path}/brightness ]; then
        echo "You don't have the right permissions" >&2
        exit 1
    fi

    # Only if there is a file for max brightness we change the value of brightness
    if [ -f ${path}/max_brightness ]; then
        # Get values from system files
        max=$(cat ${path}/max_brightness)
        current=$(cat ${path}/brightness)
        delta=1

        if [ ${max} -gt 10 ]; then
            delta=$((${max}/10))
        fi

        case $1 in
            up)
                new=$((${current}+${delta}))

                if [ ${new} -gt ${max} ]; then
                    echo ${max} > ${path}/brightness
                else
                    echo ${new} > ${path}/brightness
                fi
                ;;
            down)
                new=$((${current}-${delta}))

                if [ ${new} -lt 0 ]; then
                    echo 0 > ${path}/brightness
                else
                    echo ${new} > ${path}/brightness
                fi
                ;;
        esac

        # Save the new value to users config file
#       make_config
    else
        echo "System file missing" >&2
        exit 1
    fi
}

set_defaults() {

    echo 0 > ${pathKeyboard}/brightness
    #echo $(cat ${pathScree}/max_brightness) > ${pathScree}/brightness
    echo 825 > ${pathScree}/brightness

}

# TODO: Not tested or implemented
read_value_from_config() {

    while [ ! $UID -ge 1000 ]; do
        sleep 1
    done

    [ ! -f ${configFile} ] && make_config

    # Source the settings
    . ${configFile}

    echo ${keyboard} > ${pathKeyboard}/brightness
    echo ${screen} > ${pathScree}/brightness

}

make_config() {

    cat >${configFile} <<EOL
    keyboard=$(cat ${pathKeyboard}/brightness)
    screen=$(cat ${pathScree}/brightness)
EOL

}

print_help() {
    echo ""
    echo "This script is used to controll lights on asus zenbook"
    echo "------------------------------------------------------"
    echo "Flags are:"
    echo "-s = Sets values for screen brightness"
    echo "-k = Sets values for keyboard brightness"
    echo "-p = Sets the correct permisson on a necessary system file, need root privileges"
    echo "-u = Increase the brightness one step"
    echo "-d = Decrease the brightness one step"
    echo "-h = Prints this help text"
    echo ""
}

while getopts ":skpudh" option; do
    case $option in
        s) path=${pathScree} ;;
        k) path=${pathKeyboard} ;;
        p) set_permission ;;
        u) set_brightness up ;;
        d) set_brightness down ;;
        h) print_help ;;
        ?) echo "${OPTARG} is not a valid flag option!" >&2
           exit 1
           ;;
    esac
done

exit

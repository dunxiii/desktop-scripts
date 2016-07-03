#!/bin/bash

STEP=2

get_active_sink() {
    ACTIVE_SINK=$(pacmd list-sinks | grep '* index:' | grep -o '[0-9]*')
}

set_volume() {
    get_active_sink
    pactl set-sink-volume ${ACTIVE_SINK} ${1}${STEP}%
}

follow_sources_to_active_sink() {
    get_active_sink
    pacmd list-sink-inputs | awk '/index:/{print $2}' | xargs -r -I{} pacmd move-sink-input {} ${ACTIVE_SINK}
}

toggle_sink() {
    INACTIVE_SINK=$(pacmd list-sinks | grep 'index:' | grep -v '*' | grep -o '[0-9]*')
    pactl set-default-sink ${INACTIVE_SINK}
}

mute_sink() {
    get_active_sink
    pactl set-sink-mute ${ACTIVE_SINK} toggle
}

while getopts ":v:s:fmt" option; do
    case ${option} in
        v) set_volume ${OPTARG} ;;
        f) follow_sources_to_active_sink ;;
        m) mute_sink ;;
        t) toggle_sink ;;
        s) STEP=${OPTARG} ;;
    esac
done

exit 0

#!/bin/bash

STEP=2

get_active_sink() {
    # If one sink is running
    ACTIVE_SINK=$(pacmd list-sinks | grep -B 4 RUNNING | head -n 1 | grep -o '[0-9]*')

    # Else take default
    if [[ ${ACTIVE_SINK} == "" ]]; then
        ACTIVE_SINK=$(pacmd list-sinks | grep '* index:' | grep -o '[0-9]*')
    fi
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

while getopts ":v:s:fmto" option; do
    case ${option} in
        v) set_volume ${OPTARG} ;;
        f) follow_sources_to_active_sink ;;
        m) mute_sink ;;
        t) toggle_sink ;;
        s) STEP=${OPTARG} ;;
        o) output_vol=true
    esac
done

if [[ ${output_vol} ]]; then
    get_active_sink
    pactl list sinks | grep '^[[:space:]]Volume:' | \
        head -n $(( ${ACTIVE_SINK} + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
fi

exit 0

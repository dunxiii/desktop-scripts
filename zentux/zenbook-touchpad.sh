#!/bin/bash

# Get the device id for the touchpad
device_id=$(xinput --list | grep -Eo 'Touchpad\s*id\=[0-9]{1,2}' | grep -Eo '[0-9]{1,2}')

# Get the current state of the touchpad, 1 = on, 0 = off
device_state=$(xinput --list-props ${device_id} | grep 'Device Enabled' | awk '{print $4}')

# If state is given as argument
if [ $# -gt 0 ]; then
	# If argument is disable
	if [ $1 == "disable" ]; then
        xinput disable ${device_id}

	# If argument is enable
	elif [ $1 == "enable" ]; then
	    xinput enable ${device_id}
	fi
# No arguments given
else
    # If no argument is given, toggle
    [ ${device_state} -eq 1 ] && xinput disable ${device_id} || xinput enable ${device_id}
fi


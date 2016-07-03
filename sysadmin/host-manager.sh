#!/bin/bash
HOSTS=$(cat ~/.ssh/config | \
    awk '
        BEGIN { RS = "\n\n" }
        $1 == "Host" && $2 != "*" {
            host = $2;
            hostname = $4;
            user = $6;
            preferredauthentications = $8;
            printf "%s,%s,%s,%s\n", host, hostname, user, preferredauthentications;
        }
')

SSHFS_DIR=~/Share/sshfs
SSHCNF=~/.ssh/config

#HELP_COLOR="#d3ff00"
HELP_COLOR="#268BD2"
# TODO: Clean up, make more readable and maintainable
HELP="<span color='${HELP_COLOR}'>Return</span>: ssh&#09;<span color='${HELP_COLOR}'>Alt+f</span>: sftp&#09;<span color='${HELP_COLOR}'>Alt+c</span>: copy pass
&#09;&#09;<span color='${HELP_COLOR}'>Alt+s</span>: sshfs&#09;<span color='${HELP_COLOR}'>Alt+e</span>: edit pass"

# TODO: Clean up, make seperate function for sshfs?
ssh_app () {
    if [[ "${1}" = "sshfs" ]]; then
        command="sshfs -F ${SSHCNF} ${hostname}: ${SSHFS_DIR}"
        wait="true"
    else
        command="${1} -F ${SSHCNF} ${hostname}"
    fi

    if [[ "${preferredauthentications}" = "publickey" ]]; then
        ${command}
    elif [[ "${preferredauthentications}" = "keyboard-interactive" ]]; then
        echo -e "Server does not support sshpass and has no ssh key depolyed!"
        echo -e "Password for server has been placed in your clipboard, just paste it now.\n"
        pass --clip "${hostname}"
        ${command}
    else
        if [[ "${1}" = "sshfs" ]]; then
            ${command} -o ssh_command="sshpass -p $(pass show "${hostname}" | head -n 1) ssh"
        else
            sshpass -p "$(pass show "${hostname}" | head -n 1)" ${command}
        fi
    fi

    if [[ $? -eq 0 ]] && [[ "${wait}" = true ]]; then
            echo -e "Home folder for remote user ${user} mounted at ${SSHFS_DIR} as long as this terminal is open"
            read -rp "Press [Enter] key to close sshfs mount"
    fi
}

# Print out host menu
selection=$(
    echo -e "$( echo "${HOSTS}" \
    | cut -d ',' -f 1 )" \
    | rofi -dmenu -fullscreen -p "Host:" -mesg "${HELP}" \
        -kb-custom-1 "Alt+f" \
        -kb-custom-2 "Alt+s" \
        -kb-custom-3 "Alt+e" \
        -kb-custom-4 "Alt+c"
)

ROFI_EXIT=$?

# Fetch password from pass and open SSH session in new terminal window
for host in ${HOSTS}; do
    hostname=$(     cut -d ',' -f 1 <<< "${host}")
    ip=$(           cut -d ',' -f 2 <<< "${host}")
    user=$(         cut -d ',' -f 3 <<< "${host}")
    preferredauthentications=$(cut -d ',' -f 4 <<< "${host}")

    if [ "${hostname}" = "${selection}" ]; then

        # Add hash to known_hosts for extra security
        grep "${ip}" ~/.ssh/known_hosts &>/dev/null
        if [[ ! $? -eq 0 ]]; then
            ssh-keyscan -t rsa "${ip}" >> ~/.ssh/known_hosts
        fi

        # TODO: Add functionality: ping, nmap, mtr
        case "${ROFI_EXIT}" in
            0)
                ssh_app ssh
                ;;
            10)
                ssh_app sftp
                ;;
            11)
                ssh_app sshfs
                ;;
            12)
                pass edit "${hostname}"
                ;;
            13)
                nohup pass --clip "${hostname}"
                ;;
        esac
    fi
done

exit

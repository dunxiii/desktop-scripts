#!/usr/bin/env bash
HOSTS=$(awk '
        BEGIN { RS = "\n\n" }
        $1 == "Host" && $2 != "*" {
            host = $2;
            hostname = $4;
            user = $6;
            preferredauthentications = $8;
            printf "%s,%s,%s,%s\n", host, hostname, user, preferredauthentications;
        }' < ~/.ssh/config)

SSHFS_DIR=~/Share/sshfs
SSHCNF=~/.ssh/config

#KEY_COLOR="#d3ff00"
KEY_COLOR="#268BD2"
set_key_color() {
    echo "<span color='${KEY_COLOR}'>${1}</span>: ${2}&#09;"
}

pass_has_entry() {
    pass show "${1}" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        return
    else
        echo -e "No entry for ${1} in pass!"
        echo -e "Press [Enter] to continue"
        read -rp "Press [c] to create entry for host now: " -n 1
        if [[ "${REPLY}" = c ]]; then
            pass edit "${hostname}"
        fi
        exit 0
    fi
}

ssh_app () {

    # If ssh keys is used
    if [[ "${preferredauthentications}" = "publickey" ]]; then
        ${1}

    # If host runs BSD and does not accept sshpass method
    elif [[ "${preferredauthentications}" = "keyboard-interactive" ]]; then
        pass_has_entry "${hostname}"

        echo -e "Server does not support sshpass and has no ssh key depolyed!"
        echo -e "Password for server has been placed in your clipboard, just paste it now.\n"
        pass --clip "${hostname}"
        ${1}

    # If sshpass is used
    else
        pass_has_entry "${hostname}"

        if [[ "${1}" = *"sshfs"* ]]; then
            ${1} -o ssh_command="sshpass -p $(pass show "${hostname}" | head -n 1) ssh"

            if [[ $? -eq 0 ]]; then
                echo -e "Home directory for remote user ${user} mounted at ${SSHFS_DIR} as long as this terminal is open"
                read -rp "Press [Enter] to close sshfs mount"
            else
                echo -e "Could not mount directory for reomte user ${user} at ${SSHFS_DIR}!"
                read -rp "Press [Enter] to continue"
            fi
        else
            sshpass -p "$(pass show "${hostname}" | head -n 1)" ${1}
        fi
    fi
}

generate_pass() {
    selection=$(echo "" | rofi -dmenu -i -fullscreen -p "Length: " -mesg "Insert the lenght of desired password")

    while true; do
        clear

        # TODO else
        if [ "${selection}" -eq "${selection}" ]; then
            pass=$(</dev/urandom tr -dc 0-9a-zA-Z_ | head -c "${selection}")
            echo -e "Your generated password is: ${pass}"
        fi

        echo -e "Press [c] to copy to clipboard"
        echo -e "Press [g] to generate new password"
        read -rp "Press [Enter] to continue" -n 1

        case ${REPLY} in
            c)
                nohup sh -c "echo ${pass} | xclip -selection c &"
                break
                ;;
            g)
                continue
                ;;
            *)
                break
                ;;
        esac
    done
}

main() {

    HELP+="$(set_key_color "Return" "ssh")"
    HELP+="$(set_key_color "Alt+f" "sftp")"
    HELP+="$(set_key_color "Alt+c" "copy pass")"
    HELP+="$(set_key_color "Alt+g" "gen passwd")"
    HELP+="&#013;&#09;&#09;"
    HELP+="$(set_key_color "Alt+s" "sshfs")"
    HELP+="$(set_key_color "Alt+e" "edit pass")"

    # Print out host menu
    selection=$(
        echo -e "$( echo "${HOSTS}" \
        | cut -d ',' -f 1 )" \
        | rofi -dmenu -i -fullscreen -p "Host: " -mesg "${HELP}" \
            -kb-move-word-forward "" \
            -kb-custom-1 "Alt+f" \
            -kb-custom-2 "Alt+s" \
            -kb-custom-3 "Alt+e" \
            -kb-custom-4 "Alt+c" \
            -kb-custom-5 "Alt+g"
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
                ssh-keyscan -T 5 -t rsa "${ip}" >> ~/.ssh/known_hosts
            fi

            case "${ROFI_EXIT}" in
                0)
                    ssh_app "ssh -o ConnectTimeout=5 -F ${SSHCNF} ${hostname}"
                    ;;
                10)
                    ssh_app "sftp -o ConnectTimeout=5 -F ${SSHCNF} ${hostname}"
                    ;;
                11)
                    ssh_app "sshfs -F ${SSHCNF} ${hostname}: ${SSHFS_DIR}"
                    ;;
                12)
                    pass edit "${hostname}"
                    ;;
                13)
                    nohup pass --clip "${hostname}"
                    ;;
                14)
                    generate_pass "${selection}"
                    ;;
            esac

            exit
        fi
    done
}

main
exit

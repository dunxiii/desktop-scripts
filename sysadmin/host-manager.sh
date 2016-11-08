#!/usr/bin/env bash

# TODO ~/.ssh/config shall only have default config with wildcard
# TODO How to allow range of hosts to have same PW?

#STORE="/home/jack/.password-store-new"
STORE=~/.password-store-new
GPG_RECIPIENT=$(< "${STORE}/.gpg-id")
# TODO mark hosts that does not have a configured user?
HOSTS=$(
    find "${STORE}/" -type f ! -name ".*" | \
        sed -e "s|${STORE}/||" | \
        sort
)
SSHFS_DIR=~/Share
declare -A User

# TODO Use this for future versions, not used today
read -r -d '' TEMPLATE << EOB
# vim: set syntax=sh:
# Hostname: name or IP
Hostname=
Port=
User[jack]=""
User[root]=""
# Method: pass / key
Method=pass
Note=""
EOB

set_key_color() {
    #KEY_COLOR="#d3ff00"
    KEY_COLOR="#268BD2"
    echo "<span color='${KEY_COLOR}'>${1}</span>: ${2}&#09;"
}

ssh_app() {

    case "${1}" in
        ssh)
            ssh.exp "${1}" "-p ${Port:-22}" "${SEL_USER}" "${Hostname}" "${PASSWD:-none}"
            ;;
        sftp)
            ssh.exp "${1}" "-P ${Port:-22}" "${SEL_USER}" "${Hostname}" "${PASSWD:-none}"
            ;;
        sshfs)
            SSHFS_DIR="${SSHFS_DIR}/${SEL_HOST/\//-}"
            if [[ ! -d "${SSHFS_DIR}" ]]; then
                mkdir -p "${SSHFS_DIR}"
            fi

            echo -e "Home directory for remote user ${SEL_USER} are gonna be mounted at ${SSHFS_DIR} as long as this terminal is open"
            echo -e "Press \033[1;4m[Enter]\033[0m to unmount and close"
            ssh.exp "${1}" "-p ${Port:-22}" "${SEL_USER}" "${Hostname}" "${PASSWD:-none}" "${SSHFS_DIR}"
            EXIT=$?
            echo "sshfs closed"

            if [[ "${EXIT}" -ne 0 ]]; then
                echo -e "Could not mount directory for remote user ${SEL_USER} at ${SSHFS_DIR}!"
                read -rp "Press [Enter] to continue"
            else
                fusermount -u -z "${SSHFS_DIR}" 2> /dev/null
            fi

            [[ -d "${SSHFS_DIR}" ]] && rmdir "${SSHFS_DIR}"
            ;;

        esac
}

vpn_app() {

    vpn.exp "${Hostname}:${Port}" "${SEL_USER}" "${PASSWD}"

}

require_passwd() {

    if [[ -z "${PASSWD}" ]] && [[ "${Method}" == pass ]]; then
        echo -e "Password needs to be set for this user and method!"
        exit 1
    fi
}

# TODO Use this for future versions, not used today
new_host() {

    NEW_TEMP=$(mktemp)
    echo -n "${TEMPLATE}" > "${NEW_TEMP}"

    "${EDITOR}" "${NEW_TEMP}"

    diff <(echo -n "${TEMPLATE}") "${NEW_TEMP}"
    if [[ $? -ne 0 ]]; then

        if [[ -f "${STORE}/${SEL_HOST}" ]]; then
            echo -e ""
        fi


        mv "${NEW_TEMP}" "${STORE}/${SEL_HOST}"
        # TODO source new file?
    fi
}

main() {

    # Print list with hosts
    SEL_HOST=$(
        echo "${HOSTS}" | \
            rofi -dmenu -i -fullscreen -p "Host: " \
            -kb-custom-1 "Alt+n" \
    )

    EXIT=$?

    case "${EXIT}" in
        0)
            source "${STORE}/${SEL_HOST}"
            ;;
        *)
            exit 1
            ;;
    esac

    # TODO What if sshkey is used?
    # Mark users without password red, if Method is pass
    for i in "${!User[@]}"; do
        if [[ -z "${User[${i}]}" ]]; then
            USER_LIST+="<span color='#ff0000'>${i}</span>\n"
        else
            USER_LIST+="${i}\n"
        fi
    done

    if [[ "${SEL_HOST}" == *"VPN"* ]]; then
        # VPN
        VPN=true
        HELP+="$(set_key_color "Return" "vpn")"
        HELP+="$(set_key_color "Alt+n" "new pass")"
    else
        # SSH
        SSH=true
        HELP+="$(set_key_color "Return" "ssh")"
        HELP+="$(set_key_color "Alt+f" "sftp")"
        HELP+="$(set_key_color "Alt+s" "sshfs")"
        HELP+="$(set_key_color "Alt+c" "copy pass")"
        HELP+="$(set_key_color "Alt+n" "new pass")"
    fi

    # TODO move kb-custom into if above?
    # TODO Other view if is is VPN access
    SEL_USER=$(
        echo -ne "${USER_LIST}" | \
            rofi -dmenu -i -fullscreen -p "User: " -mesg "${HELP}" -markup-rows \
            -kb-move-word-forward "" \
            -kb-custom-1 "Alt-f" \
            -kb-custom-2 "Alt-s" \
            -kb-custom-3 "Alt-c" \
            -kb-custom-4 "Alt-n" \
            -kb-custom-5 "Alt-v" \
    )

    EXIT=$?

    # TODO What if ESC was pressed? Move this part after case? Make function?
    # TODO What if key is used?
    # If marked red, strip html
    if [[ "${SEL_USER}" == *"span"* ]]; then
        # Method=key goes here... how to handle better?
        SEL_USER=$(echo "${SEL_USER}" | sed -e "s|<.*>\(.*\)</.*>|\1|")
    else
        PASSWD=$(echo -n ${User[${SEL_USER}]} | base64 --decode | gpg --quiet --decrypt --no-mdc-warning)
    fi

    case "${EXIT}" in
        0)
            require_passwd

            if [[ "${SSH}" ]]; then
                ssh_app ssh
            elif [[ "${VPN}" ]]; then
                vpn_app
            fi
            ;;
        10)
            require_passwd
            ssh_app sftp
            ;;
        11)
            require_passwd
            ssh_app sshfs
            ;;
        12)
            require_passwd

            # Copy password to clipboard
            echo -n "${PASSWD}" | xclip -i -selection clipboard
            # TODO Which password is copied? tell user
            echo -e "Password is copied to clipboard and will be cleard in \033[1;4m30s\033[0m\n"
            nohup sh -c "sleep 30 && xclip -i -selection clipboard /dev/null" > /dev/null 2>&1 &
            ;;
        13)
            # TODO Ask if user is sure to change pass
            # TODO read password two times and control that they are the same
            # Set new password for selected user
            read -es -p "$(echo -e "Enter new password for user \033[1;4m${SEL_USER}\033[0m on \033[1;4m${SEL_HOST}\033[0m: ")" NEW_PASSWD
            echo -e "\n"

            NEW_PASSWD=$(echo -n "${NEW_PASSWD}" | gpg --encrypt --default-recipient-self | base64 --wrap=0)
            sed -i -re "s|(User\[${SEL_USER}\]=)[^=].*$|\1\"${NEW_PASSWD}\"|" "${STORE}/${SEL_HOST}"
            ;;
        14)
            require_passwd
            vpn_app
            ;;
        *)
            exit 1
            ;;
    esac
}

main
exit

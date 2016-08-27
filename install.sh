#!/usr/bin/env bash
shopt -s nullglob

HOOKS_DEST="/etc/pacman.d/hooks"
SH_DEST="/usr/local/bin"
SERVICE_DEST="/etc/systemd/system"
PWD="$(cd $(dirname $0) && pwd)"

if [[ ! -d "${HOOKS_DEST}" ]]; then
    mkdir -p "${HOOKS_DEST}"
fi

for file in ${PWD}/arch/pacman/hooks/*.hook; do
    ln -fs "$(realpath "${file}")" "${HOOKS_DEST}/"
done

for file in ${PWD}/{i3,sysadmin}/*.sh; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

# Host specific
for file in ${PWD}/$(hostname)/*.sh; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

for file in ${PWD}/$(hostname)/service/*.service; do
    ln -fs "$(realpath "${file}")" "${SERVICE_DEST}/"
    # Systemd bug forces me to use realpath instead of basename...
    # https://github.com/systemd/systemd/issues/3010
    systemctl enable --now "$(realpath "${file}")"
done

chmod -R +x "${SH_DEST}"

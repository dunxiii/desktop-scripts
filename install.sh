#!/usr/bin/env bash
shopt -s nullglob

SH_DEST="/usr/local/bin"
PWD="$(cd $(dirname $0) && pwd)"

for file in ${PWD}/{i3,sysadmin}/*; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

# Host specific
for file in ${PWD}/$(hostname)/*.sh; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

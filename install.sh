#!/usr/bin/env bash
shopt -s nullglob

SH_DEST="/usr/local/bin"
SERVICE_DEST="/etc/systemd/system"

for file in ./{i3,arch}/*.sh; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

# Host specific
for file in ./$(hostname)/*.sh; do
    ln -fs "$(realpath "${file}")" "${SH_DEST}/"
done

for file in ./$(hostname)/service/*.service; do
    ln -fs "$(realpath "${file}")" "${SERVICE_DEST}/"
    # Systemd bug forces me to use realpath instead of basename...
    # https://github.com/systemd/systemd/issues/3010
    systemctl enable --now "$(realpath "${file}")"
done

chmod -R +x "${SH_DEST}"

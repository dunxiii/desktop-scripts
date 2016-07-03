#!/usr/bin/env bash

# Partial upgrade is not supported so use this script with -Su or equal

shopt -s nullglob

reflector --sort score --threads 5 -a 10 -c SE -c DK -c NO -c FI -n 15 --save /etc/pacman.d/mirrorlist

pacman -Syy

for file in /etc/pacman.d/mirrorlist.*; do
    rm "${file}"
done

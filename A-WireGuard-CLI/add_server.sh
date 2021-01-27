#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e

keys_dir=~/.wireguard
if ! [ -f "$keys_dir"/private ] || ! [ -f "$keys_dir"/public ]; then
    mkdir -p "$keys_dir"
    (umask 077; sudo wg genkey | tee "$keys_dir"/private | wg pubkey > "$keys_dir"/public)
fi

echo "Please share this key with your server/peer then press enter"
cat "$keys_dir"/public
read

conf_file=client1.conf
printf "Please add the config file received from your server/peer to /etc/wireguard/\nThen make sure it has no spaces and ends with .conf\nThen enter it's final name ($conf_file): "; read conf_file_
conf_file=${conf_file_:-$conf_file}
if ! sudo [ -f "/etc/wireguard/$conf_file" ]; then echo "Error: file not found /etc/wireguard/$conf_file. Please add it and try again"; exit 1; fi

sudo sed "s/<client privatekey>/$(cat "$keys_dir"/private)/" "/etc/wireguard/$conf_file" -i
echo "Configuration file update successfully with your private key"

interface=${conf_file%.conf}
wg-quick up "$interface"

echo "Connection initiated. You may stop it with: 'wg-quick down $interface' and start it again with 'wg-quick up $interface'"


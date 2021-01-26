#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e
stt=$SECONDS; trap 'echo Total duration: $(($SECONDS-$stt)) seconds' EXIT

net=1
lan_name=enp1s0
server_wireguard_address=172.$net.1.1

conf_file=server$net.conf

keys_dir=~/.wireguard
#sudo apt install wireguard

if ! [ -f "$keys_dir"/private ] || ! [ -f "$keys_dir"/public ]; then
    mkdir -p "$keys_dir"
    sudo wg genkey | tee "$keys_dir"/private | wg pubkey > "$keys_dir"/public
fi

if ! sudo [ -f /etc/wireguard/$conf_file ]; then
sudo tee /etc/wireguard/$conf_file << EOF > /dev/null
[Interface]
Address = $server_wireguard_address
PrivateKey = $(cat "$keys_dir"/private)
ListenPort = 51820

PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $lan_name -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $lan_name -j MASQUERADE

EOF
else echo "Not replacing /etc/wireguard/$conf_file. You may delete it and rerun the script"; fi

echo "Configuration ready. You may share your public key with your peers:"
cat "$keys_dir"/public
echo

wg-quick up ${conf_file%.conf}

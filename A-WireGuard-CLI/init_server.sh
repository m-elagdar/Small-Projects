#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e

net=1
: ${lan_name:=$(ip route | grep default | grep -oP "(?<=dev )\S+")}
echo "Setting interface for network forwarding to $lan_name. Set \$lan_name to change it"
: ${server_wireguard_address:=172.$net.1.1}
echo "Setting server address to $server_wireguard_address. Set \$server_wireguard_address to change it"

: ${conf_file:=server$net.conf}

keys_dir=~/.wireguard
#sudo apt install wireguard

if ! command -v wg-quick &> /dev/null; then echo "[ERROR] WireGuard is not installed. Please visit https://www.wireguard.com/install/"; exit 1; fi

if ! [ -f "$keys_dir"/private ] || ! [ -f "$keys_dir"/public ]; then
    mkdir -p "$keys_dir"
    (umask 077; sudo wg genkey | tee "$keys_dir"/private | wg pubkey > "$keys_dir"/public)
fi

if ! sudo [ -f /etc/wireguard/$conf_file ]; then
sudo tee /etc/wireguard/$conf_file << EOF > /dev/null
[Interface]
Address = $server_wireguard_address
PrivateKey = $(cat "$keys_dir"/private)
ListenPort = 51820

EOF

read -p "Forward your local network so your peers can connect to devices in your lan? (Y,n): " ok
if [[ $ok =~ ^([yY](es|a|up|eah)*|)$ ]]; then sudo tee -a /etc/wireguard/$conf_file << EOF > /dev/null
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $lan_name -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $lan_name -j MASQUERADE

EOF
printf "\nYour should now add/uncomment \"net.ipv4.ip_forward = 1\" in /etc/sysctl.d/99-sysctl.conf or /etc/sysctl.conf\nThen run \"sudo sysctl -p\" and make sure the line is printed.\n\nPress enter when done "; read;
fi

else echo "Not replacing /etc/wireguard/$conf_file. You may delete it and rerun the script"; fi

echo "Configuration ready. You may share your public key with your peers:"
cat "$keys_dir"/public
echo

interface=${conf_file%.conf}
wg-quick up $interface

echo -e "\nService started\nYou may stop/start it with \"sudo wg-quick down/up $interface\nAnd run-it-at-startup/or-not with \"systemctl enable/disable wg-quick@$interface\""

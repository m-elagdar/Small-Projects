#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e
log() { >&2 echo "${@}"; }

client_public_key="$1"
server_public_ip="$2"
ip="$3" # optional
shared_net="192.168.0.0/16"
net=1
server_wireguard_address=172.$net.1.1
: ${conf_file:=server$net.conf}
keys_dir=~/.wireguard
peer_names=$keys_dir/peer_names

if ! sudo [ -f /etc/wireguard/"$conf_file" ]; then echo "[ERROR] The server config is not initialized. Please run init_server.sh or set \$conf_file"; exit 1; fi 

if [ -z "$client_public_key" ]; then read -p "Please enter the CLIENT's public KEY: " client_public_key; fi
if [ -z "$server_public_ip" ]; then read -p "Please enter the SERVER's public IP: " server_public_ip; fi
read -p "[Optional] Please enter a name for the for keeping a list in $peer_names: " client_name; echo "${client_name:=unnamed} $client_public_key" >> $peer_names

if [ -z "$ip" ]; then 
    # Get a new free ip
    ip=$(sudo tac /etc/wireguard/$conf_file | grep -oP -m 1 "(?<=AllowedIPs = )\d+\.\d+\.\d+\.\d+" || printf "$server_wireguard_address")
    IFS='.' read -r -a ip <<< $ip
    echo "Last ip: $ip"
    if ((${ip[3]}<254)); then ip[3]=$((${ip[3]}+1))
    elif ((${ip[2]}<254)); then ip[2]=$((${ip[2]}+1)); ip[3]=1
    else log "couldn't find an ip by auto incrementing the last two octets of the last ip in the config file"; exit 1; fi
    ip=$(printf "%s." "${ip[@]}"); ip=${ip::-1}
fi

log "Appending client to /etc/wireguard/$conf_file with ip: $ip"

sudo tee -a /etc/wireguard/"$conf_file" << EOF > /dev/null
[Peer]
PublicKey = $client_public_key
AllowedIPs = ${ip} 
EOF
echo "conf updated"

# Update running service
interface=${conf_file%.conf}
sudo wg syncconf "$interface" <(sudo wg-quick strip "$interface") || { wg-quick down "$interface"; wg-quick up "$interface"; }

peer_conf_file=client1.conf
log "Peer added successfully, here's the peer's suggested config saved to $peer_conf_file. Please replace <client privatekey> or use add_server.sh"
tee $peer_conf_file << EOF
[Interface]
Address = $ip
PrivateKey = <client privatekey>
ListenPort = 21841

[Peer]
PublicKey = $(cat "$keys_dir"/public)
Endpoint = $server_public_ip:51820
AllowedIPs = $shared_net
EOF


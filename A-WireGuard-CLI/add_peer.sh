#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e
log() { >&2 echo "${@}"; }
logp() { >&2 printf "${@}"; }

client_public_key="$1"
server_public_ip="$2"
: ${ip:="$3"} # optional
: ${shared_net:="192.168.0.0/16"}
net=1
: ${conf_file:=server$net.conf}
keys_dir=~/.wireguard
peer_names=$keys_dir/peer_names

if ! sudo [ -f /etc/wireguard/"$conf_file" ]; then log "[ERROR] The server config is not initialized. Please run init_server.sh or set \$conf_file"; exit 1; fi 

if [ -z "$client_public_key" ]; then logp "Please enter the CLIENT's public KEY: "; read client_public_key; fi
if [ -z "$server_public_ip" ]; then logp "Please enter the SERVER's public IP: "; read server_public_ip; fi
logp "[Optional] Please enter a name for the for keeping a list in $peer_names: "; read client_name; echo "${client_name:=unnamed} $client_public_key" >> $peer_names
server_wireguard_address=$(sudo grep -oP "(?<=Address = )\d+\.\d+\.\d+\.\d+" /etc/wireguard/"$conf_file")

if [ -z "$ip" ]; then 
    # Get a new free ip
    ip=$(sudo tac /etc/wireguard/$conf_file | grep -oP -m 1 "(?<=AllowedIPs = )\d+\.\d+\.\d+\.\d+" || printf "$server_wireguard_address")
    IFS='.' read -r -a ip <<< $ip
    if ((${ip[3]}<254)); then ip[3]=$((${ip[3]}+1))
    elif ((${ip[2]}<254)); then ip[2]=$((${ip[2]}+1)); ip[3]=1
    else log "couldn't find an ip by auto incrementing the last two octets of the last ip in the config file"; exit 1; fi
    ip=$(printf "%s." "${ip[@]}"); ip=${ip::-1}
    log "Auto selected a new IP address: $ip. Set \$ip for manual"
fi

log "Appending client to /etc/wireguard/$conf_file with ip: $ip"

sudo tee -a /etc/wireguard/"$conf_file" << EOF > /dev/null
[Peer]
PublicKey = $client_public_key
AllowedIPs = $ip

EOF
log "Server configuration edited"

# Update running service
interface=${conf_file%.conf}
sudo bash -c "wg syncconf \"$interface\" <(wg-quick strip \"$interface\")"

logp "\nDid the server share a network {$shared_net, no}: "; read shared_net_;
if [ -z $shared_net_ ]; then shared_net_s=", $shared_net";
elif [[ $shared_net_ =~ .*\..* ]]; then shared_net_s=", $shared_net_";
else shared_net_s=; fi

peer_conf_file=client1.conf
log -e "\nPeer added successfully, here's the peer's suggested config saved to $peer_conf_file. Please ask the client to replace <client privatekey> or use add_server.sh\n"
tee $peer_conf_file << EOF
[Interface]
PrivateKey = <client privatekey>
Address = $ip
ListenPort = 21841

[Peer]
PublicKey = $(cat "$keys_dir"/public)
Endpoint = $server_public_ip:51820
AllowedIPs = $server_wireguard_address$shared_net_s

EOF


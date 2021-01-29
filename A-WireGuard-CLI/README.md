# A CLI for WireGuard

## Steps for the server
1. Run [init_server.sh](init_server.sh)
1. To add a peer, run [add_peer.sh](add_peer.sh)

## Steps for the client
1. Linux: Run [add_server.sh](add_server.sh)
1. Windows
    1. Run the official app
    1. Press Ctrl+N (Or click the little arrow next to "Add Tunnel" then click "Add empty tunnel...")
    1. Copy the "Public key" and send it to the server-admin/peer and get your new configuration
    1. Update all the lines EXCEPT the "PrivateKey = ..." line
    1. Click Save then Activate

## References
1. [How to easily configure WireGuard - Stavros' Stuff](https://www.stavros.io/posts/how-to-configure-wireguard/)

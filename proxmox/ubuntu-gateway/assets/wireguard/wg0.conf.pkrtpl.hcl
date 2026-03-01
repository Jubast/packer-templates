[Interface]
Address = ${wireguard_server_address_ipv4}/24
ListenPort = ${wireguard_server_listen_port}
PrivateKey = ${wireguard_server_private_key}
PostUp = iptables -A FORWARD -i %i -o ${wireguard_server_network_interface} -j ACCEPT; iptables -A FORWARD -i ${wireguard_server_network_interface} -o %i -m state --state ESTABLISHED,RELATED -j ACCEPT; iptables -t nat -A POSTROUTING -s ${wireguard_server_subnet_address_ipv4}/24 -o ${wireguard_server_network_interface} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -o ${wireguard_server_network_interface} -j ACCEPT; iptables -D FORWARD -i ${wireguard_server_network_interface} -o %i -m state --state ESTABLISHED,RELATED -j ACCEPT; iptables -t nat -D POSTROUTING -s ${wireguard_server_subnet_address_ipv4}/24 -o ${wireguard_server_network_interface} -j MASQUERADE
%{ for peer in wireguard_peers ~}


[Peer]
# ${peer.name}
PublicKey = ${peer.public_key}
PresharedKey = ${peer.preshared_key}
AllowedIPs = ${peer.address_ipv4}/32
%{ endfor ~}

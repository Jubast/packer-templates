#!/bin/bash -e
################################################################################
##  File: configure-system.sh
##  Desc: Configures the system (automatic updates, etc..)
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

install_packages=(unattended-upgrades qemu-guest-agent)

# install
echo "[INFO] Installing packages.."
apt-get update
apt-get install -y ${install_packages[@]}

# configuration
echo "[INFO] Configuring packages.."

# enable and start unattended-upgrades service
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

# enable and start qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

# enable periodic TRIM for discard/SSD support
systemctl enable fstrim.timer
systemctl start fstrim.timer

echo "[INFO] Configuring system.."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_unprivileged_port_start=53" >> /etc/sysctl.conf

# configure systemd-resolved to use AdGuard Home as upstream DNS
echo "[INFO] Configuring systemd-resolved to use AdGuard Home as upstream DNS.."
sed -i 's/#DNS=/DNS=127.0.0.1:5353/' /etc/systemd/resolved.conf
sed -i "s/#DNSStubListenerExtra=/DNSStubListenerExtra=${WIREGUARD_SERVER_ADDRESS_IPV4}/" /etc/systemd/resolved.conf
systemctl restart systemd-resolved

# configure ufw firewall rules
echo "[INFO] Configuring firewall rules.."

# WireGuard
ufw allow 51820/udp comment "WireGuard"

# Nginx Proxy Manager
ufw allow 80/tcp   comment "Nginx Proxy Manager - HTTP"
ufw allow 443/tcp  comment "Nginx Proxy Manager - HTTPS"
ufw allow 8081/tcp   comment "Nginx Proxy Manager - UI"

# AdGuard Home
ufw allow 53/tcp   comment "AdGuard Home - DNS"
ufw allow 53/udp   comment "AdGuard Home - DNS"
ufw allow 8082/tcp comment "AdGuard Home - UI"

ufw reload

# tests
echo "[INFO] Testing packages.."
unattended-upgrades --dry-run --debug
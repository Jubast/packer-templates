#!/bin/bash -e
################################################################################
##  File: install-wireguard.sh
##  Desc: Installs and configures wireguard vpn
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

install_packages=(wireguard)

# install
echo "[INFO] Installing packages.."
apt-get update
apt-get install -y ${install_packages[@]}

# configuration
echo "[INFO] Configuring packages.."
mkdir -p /etc/wireguard
mv /tmp/wireguard/wg0.conf /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf

cat /etc/wireguard/wg0.conf

# enable & start the wireguard server
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

# tests
echo "[INFO] Testing packages.."
wg -v
if systemctl is-active --quiet wg-quick@wg0.service; then
    echo "[INFO] Systemctl service wg-quick@wg0.service is active."
else
    echo "[ERROR] Systemctl service wg-quick@wg0.service is not active." >&2
    exit 1
fi
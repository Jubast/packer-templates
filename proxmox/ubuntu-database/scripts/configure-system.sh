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

# tests
echo "[INFO] Testing packages.."
unattended-upgrades --dry-run --debug
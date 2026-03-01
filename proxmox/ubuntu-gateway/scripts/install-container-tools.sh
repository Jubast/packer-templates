#!/bin/bash -e
################################################################################
##  File: install-container-tools.sh
##  Desc: Installs podman and podman-compose
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

install_packages=(podman podman-compose)

# install
echo "[INFO] Installing packages.."
apt-get update
apt-get install -y ${install_packages[@]}

# configuration
echo "[INFO] Configuring packages.."
touch /etc/containers/nodocker

# tests
echo "[INFO] Testing packages.."
podman -v
podman-compose -v

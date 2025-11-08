#!/bin/bash -e
################################################################################
##  File: enable-user-lingering.sh
##  Desc: Enables systemd lingering for container user (run as root)
################################################################################

set -e
set -u
set -o pipefail

CONTAINER_USER="${FOR_USER}"

echo "==> Enabling systemd lingering for user: ${CONTAINER_USER}"

# Enable lingering (allows user services to run without login)
loginctl enable-linger "${CONTAINER_USER}"

# Create user systemd directory
USER_SYSTEMD_DIR="/home/${CONTAINER_USER}/.config/systemd/user"
mkdir -p "${USER_SYSTEMD_DIR}"
chown -R "${CONTAINER_USER}:${CONTAINER_USER}" "/home/${CONTAINER_USER}/.config"

echo "==> Lingering enabled for ${CONTAINER_USER}"
echo "    User services will start on boot without requiring login"
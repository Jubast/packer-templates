#!/bin/bash -e
################################################################################
##  File: configure-system.sh
##  Desc: Configures the system (automatic updates, media directories, firewall)
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

MEDIA_USER="${FOR_USER}"

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

# create media and download directories
echo "[INFO] Creating media directories.."
mkdir -p /srv/media/movies
mkdir -p /srv/media/tv
mkdir -p /srv/media/music
mkdir -p /srv/downloads
chown -R "${MEDIA_USER}:${MEDIA_USER}" /srv/media /srv/downloads
chmod -R 755 /srv/media /srv/downloads

# configure ufw firewall rules
echo "[INFO] Configuring firewall rules.."

# Jellyfin
ufw allow 8096/tcp  comment "Jellyfin HTTP"
ufw allow 8920/tcp  comment "Jellyfin HTTPS"
ufw allow 7359/udp  comment "Jellyfin local discovery"
ufw allow 1900/udp  comment "Jellyfin DLNA"

# Sonarr
ufw allow 8989/tcp  comment "Sonarr"

# Radarr
ufw allow 7878/tcp  comment "Radarr"

# Prowlarr
ufw allow 9696/tcp  comment "Prowlarr"

# Bazarr
ufw allow 6767/tcp  comment "Bazarr"

# Jellyseerr
ufw allow 5055/tcp  comment "Jellyseerr"

# qBittorrent web UI
ufw allow 8080/tcp  comment "qBittorrent web UI"

# qBittorrent BitTorrent traffic
ufw allow 6881/tcp  comment "qBittorrent BitTorrent TCP"
ufw allow 6881/udp  comment "qBittorrent BitTorrent UDP"

ufw reload

# tests
echo "[INFO] Testing packages.."
unattended-upgrades --dry-run --debug

#!/bin/bash -e
################################################################################
##  File: configure-container-services.sh
##  Desc: Configures container services via podman-compose
##  Note: This script should be run as a normal user, NOT root
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

################################################################################
# Services
# Format: "service-name:temp-compose-filename"
################################################################################
SERVICES=(
    "mariadb:mariadb-docker-compose.yml"
    "redis:redis-docker-compose.yml"
)

TEMP_DIR="/tmp/docker"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"

################################################################################
# Function: setup_service <service-name> <temp-compose-filename>
################################################################################
setup_service() {
    local service_name="$1"
    local temp_compose_filename="$2"
    local temp_compose_file="${TEMP_DIR}/${temp_compose_filename}"
    local compose_dir="${HOME}/.local/share/containers/${service_name}"
    local compose_file="${compose_dir}/docker-compose.yml"
    local systemd_service="podman-compose-${service_name}"

    echo "==> Setting up ${service_name}..."

    if [ ! -f "${temp_compose_file}" ]; then
        echo "ERROR: Temporary compose file not found at ${temp_compose_file}"
        exit 1
    fi

    mkdir -p "${compose_dir}"
    cp "${temp_compose_file}" "${compose_file}"
    chmod 644 "${compose_file}"

    mkdir -p "${USER_SYSTEMD_DIR}"
    cat > "${USER_SYSTEMD_DIR}/${systemd_service}.service" <<EOF
[Unit]
Description=Podman Compose ${service_name}
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${compose_dir}
ExecStart=/usr/bin/podman-compose -f ${compose_file} up -d
ExecStop=/usr/bin/podman-compose -f ${compose_file} down
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable "${systemd_service}.service"
    echo "  -> Enabled ${systemd_service}.service"

    systemctl --user start "${systemd_service}.service"
    echo "  -> Started ${systemd_service}.service"
}

################################################################################
# Main
################################################################################
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: This script should NOT be run as root!"
    echo "       Run it as a normal user with sudo privileges"
    exit 1
fi

# Setup all services
for entry in "${SERVICES[@]}"; do
    service_name="${entry%%:*}"
    compose_filename="${entry##*:}"
    setup_service "${service_name}" "${compose_filename}"
done

echo "  -> Waiting for containers to become healthy..."
sleep 10

echo ""
echo "==> Container Status:"
for entry in "${SERVICES[@]}"; do
    service_name="${entry%%:*}"
    compose_dir="${HOME}/.local/share/containers/${service_name}"
    compose_file="${compose_dir}/docker-compose.yml"
    echo "  [${service_name}]"
    podman-compose -f "${compose_file}" ps
done

echo ""
echo "==> Configuration complete!"
echo "    - MariaDB: localhost:3306"
echo "    - Redis:   localhost:6379"
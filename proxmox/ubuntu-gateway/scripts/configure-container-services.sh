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
    "nginx-proxy-manager:nginx-proxy-manager-docker-compose.yml"
    "adguard-home:adguard-home-docker-compose.yml"
)

TEMP_DIR="/tmp/docker"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"

################################################################################
# Function: cleanup_service <service-name>
################################################################################
cleanup_service() {
    local service_name="$1"
    local compose_dir="${HOME}/.local/share/containers/${service_name}"
    local compose_file="${compose_dir}/docker-compose.yml"
    local systemd_service="podman-compose-${service_name}"

    echo "==> Cleaning up ${service_name}..."

    if systemctl --user is-active --quiet "${systemd_service}.service" 2>/dev/null; then
        echo "  -> Stopping ${systemd_service}.service"
        systemctl --user stop "${systemd_service}.service" || true
    fi

    if systemctl --user is-enabled --quiet "${systemd_service}.service" 2>/dev/null; then
        echo "  -> Disabling ${systemd_service}.service"
        systemctl --user disable "${systemd_service}.service" || true
    fi

    if [ -f "${USER_SYSTEMD_DIR}/${systemd_service}.service" ]; then
        echo "  -> Removing systemd service file"
        rm -f "${USER_SYSTEMD_DIR}/${systemd_service}.service"
    fi

    if [ -f "${compose_file}" ]; then
        echo "  -> Stopping and removing containers"
        cd "${compose_dir}"
        podman-compose -f "${compose_file}" down || true
    fi
}

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

# Cleanup all services first
for entry in "${SERVICES[@]}"; do
    service_name="${entry%%:*}"
    cleanup_service "${service_name}"
done

systemctl --user daemon-reload
echo "==> Cleanup completed"

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
echo "    - Nginx Proxy Manager admin UI: http://localhost:81"
echo "    - AdGuard Home setup UI:        http://localhost:3000"

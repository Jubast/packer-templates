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
    "jellyfin:jellyfin-docker-compose.yml"
    "arr:arr-docker-compose.yml"
    "qbittorrent:qbittorrent-docker-compose.yml"
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

    local temp_env_file="${TEMP_DIR}/${service_name}.env"
    if [ -f "${temp_env_file}" ]; then
        cp "${temp_env_file}" "${compose_dir}/.env"
        chmod 600 "${compose_dir}/.env"
    fi

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
# Function: setup_healthcheck_watcher
# Creates a script + systemd service+timer that restarts unhealthy containers.
################################################################################
setup_healthcheck_watcher() {
    local script_dir="${HOME}/.local/bin"
    local script_path="${script_dir}/container-healthcheck.sh"
    local systemd_service="container-healthcheck"

    echo "==> Setting up container healthcheck watcher..."

    mkdir -p "${script_dir}"
    cat > "${script_path}" <<'HEALTHCHECK_EOF'
#!/bin/bash
# Restart any podman containers whose health check is reporting unhealthy.
unhealthy=$(podman ps --filter health=unhealthy --format '{{.Names}}')
for container in ${unhealthy}; do
    echo "$(date --iso-8601=seconds) Restarting unhealthy container: ${container}"
    podman restart "${container}"
done
HEALTHCHECK_EOF
    chmod 755 "${script_path}"

    mkdir -p "${USER_SYSTEMD_DIR}"
    cat > "${USER_SYSTEMD_DIR}/${systemd_service}.service" <<EOF
[Unit]
Description=Restart unhealthy podman containers

[Service]
Type=oneshot
ExecStart=${script_path}
EOF

    cat > "${USER_SYSTEMD_DIR}/${systemd_service}.timer" <<EOF
[Unit]
Description=Check and restart unhealthy podman containers every 2 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable "${systemd_service}.timer"
    systemctl --user start "${systemd_service}.timer"
    echo "  -> Enabled and started ${systemd_service}.timer"
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
sleep 15

setup_healthcheck_watcher

echo ""
echo "==> Container Status:"
for entry in "${SERVICES[@]}"; do
    service_name="${entry%%:*}"
    compose_dir="${HOME}/.local/share/containers/${service_name}"
    compose_file="${compose_dir}/docker-compose.yml"
    echo "  [${service_name}]"
    podman-compose -f "${compose_file}" ps
done

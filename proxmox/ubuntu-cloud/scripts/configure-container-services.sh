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
    "nextcloud:nextcloud-docker-compose.yml:nextcloud.env,onlyoffice.env"
    "vaultwarden:vaultwarden-docker-compose.yml:vaultwarden.env"
)

TEMP_DIR="/tmp/docker"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"

################################################################################
# Function: setup_service <service-name> <temp-compose-filename> <env-files-csv>
################################################################################
setup_service() {
    local service_name="$1"
    local temp_compose_filename="$2"
    local env_files_csv="${3:-}"
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
    if [ -n "${env_files_csv}" ]; then
        IFS=',' read -ra env_files <<< "${env_files_csv}"
        for env_filename in "${env_files[@]}"; do
            local named_env_file="${TEMP_DIR}/${env_filename}"
            if [ -f "${named_env_file}" ]; then
                cp "${named_env_file}" "${compose_dir}/${env_filename}"
                chmod 600 "${compose_dir}/${env_filename}"
            fi
        done
    elif [ -f "${temp_env_file}" ]; then
        cp "${temp_env_file}" "${compose_dir}/.env"
        chmod 600 "${compose_dir}/.env"
    fi

    # Copy hooks directory if present
    local temp_hooks_dir="${TEMP_DIR}/${service_name}-hooks"
    if [ -d "${temp_hooks_dir}" ]; then
        cp -r "${temp_hooks_dir}" "${compose_dir}/hooks"
        find "${compose_dir}/hooks" -type f -name "*.sh" -exec chmod 755 {} \;
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
# Function: setup_nextcloud_cron
# Creates a systemd timer that runs Nextcloud background jobs every 5 minutes.
################################################################################
setup_nextcloud_cron() {
    local container_name="nextcloud_nextcloud_1"
    local systemd_service="nextcloud-cron"

    echo "==> Setting up Nextcloud cron timer..."

    mkdir -p "${USER_SYSTEMD_DIR}"

    # One-shot service that executes cron.php inside the running container
    cat > "${USER_SYSTEMD_DIR}/${systemd_service}.service" <<EOF
[Unit]
Description=Nextcloud background jobs (cron.php)
After=podman-compose-nextcloud.service
Requires=podman-compose-nextcloud.service

[Service]
Type=oneshot
ExecStart=/usr/bin/podman exec --user www-data ${container_name} php /var/www/html/cron.php
EOF

    # Timer that fires every 5 minutes
    cat > "${USER_SYSTEMD_DIR}/${systemd_service}.timer" <<EOF
[Unit]
Description=Run Nextcloud cron every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
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
# Switches Nextcloud background job mode to 'cron' via occ.
################################################################################
configure_nextcloud_background_jobs() {
    local container_name="nextcloud_nextcloud_1"
    local max_wait=240
    local elapsed=0

    echo "==> Waiting for Nextcloud to be ready (occ)..."
    until podman exec --user www-data "${container_name}" php /var/www/html/occ status --output=json 2>/dev/null | grep -q '"installed":true'; do
        if [ "${elapsed}" -ge "${max_wait}" ]; then
            echo "  [WARN] Nextcloud not ready after ${max_wait}s, skipping occ background:cron configuration."
            echo "         Run manually: podman exec --user www-data ${container_name} php occ background:cron"
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    echo "==> Waiting for Nextcloud to run post-install scripts (occ)..."
    until podman exec --user www-data "${container_name}" php /var/www/html/occ app:list --output=json 2>/dev/null | grep -q '"onlyoffice"'; do
        if [ "${elapsed}" -ge "${max_wait}" ]; then
            echo "  [WARN] Nextcloud didn't run post-install after ${max_wait}s, skipping occ background:cron configuration."
            echo "         Run manually: podman exec --user www-data ${container_name} php occ background:cron"
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    echo "  -> Setting background jobs mode to 'cron'..."
    podman exec --user www-data "${container_name}" php /var/www/html/occ background:cron
    echo "  -> Nextcloud background jobs configured to use system cron."
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
# Mainall
################################################################################
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: This script should NOT be run as root!"
    echo "       Run it as a normal user with sudo privileges"
    exit 1
fi

# Setup all services
for entry in "${SERVICES[@]}"; do
    IFS=':' read -r service_name compose_filename env_files_csv <<< "${entry}"
    setup_service "${service_name}" "${compose_filename}" "${env_files_csv}"
done

echo "  -> Waiting for containers to become healthy..."
sleep 10

setup_healthcheck_watcher

# Setup Nextcloud cron timer
setup_nextcloud_cron

# Configure Nextcloud background jobs mode
configure_nextcloud_background_jobs

echo ""
echo "==> Container Status:"
for entry in "${SERVICES[@]}"; do
    IFS=':' read -r service_name _ _ <<< "${entry}"
    compose_dir="${HOME}/.local/share/containers/${service_name}"
    compose_file="${compose_dir}/docker-compose.yml"
    echo "  [${service_name}]"
    podman-compose -f "${compose_file}" ps
done

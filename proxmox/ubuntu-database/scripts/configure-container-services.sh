#!/bin/bash -e
################################################################################
##  File: configure-container-services.sh
##  Desc: Configures the container services (databases via podman-compose)
##  Note: This script should be run as a normal user, NOT root
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

################################################################################
# Configuration
################################################################################
TEMP_COMPOSE_FILE="/tmp/docker/databases-docker-compose.yml"
COMPOSE_DIR="${HOME}/.local/share/containers/databases"
COMPOSE_FILE="${COMPOSE_DIR}/databases-docker-compose.yml"
SERVICE_NAME="podman-compose-databases"
USER_SYSTEMD_DIR="${HOME}/.config/systemd/user"

################################################################################
# Function: cleanup_services
# Description: Stops and removes all systemd services created by podman-compose
################################################################################
cleanup_services() {
    echo "==> Cleaning up existing podman-compose services..."
    
    # Stop and disable the systemd user service if it exists
    if systemctl --user is-active --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
        echo "  -> Stopping ${SERVICE_NAME}.service"
        systemctl --user stop "${SERVICE_NAME}.service" || true
    fi
    
    if systemctl --user is-enabled --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
        echo "  -> Disabling ${SERVICE_NAME}.service"
        systemctl --user disable "${SERVICE_NAME}.service" || true
    fi
    
    # Remove systemd service file if it exists
    if [ -f "${USER_SYSTEMD_DIR}/${SERVICE_NAME}.service" ]; then
        echo "  -> Removing systemd service file"
        rm -f "${USER_SYSTEMD_DIR}/${SERVICE_NAME}.service"
    fi
    
    # Stop and remove containers managed by podman-compose
    if [ -f "${COMPOSE_FILE}" ]; then
        echo "  -> Stopping and removing containers"
        cd "${COMPOSE_DIR}"
        podman-compose -f "${COMPOSE_FILE}" down || true
    fi
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    
    echo "==> Cleanup completed"
}

################################################################################
# Function: start_database_services
# Description: Starts database containers and enables them on boot via systemd
################################################################################
start_database_services() {
    echo "==> Starting database services with podman-compose..."

    # Ensure user systemd directory exists
    mkdir -p "${USER_SYSTEMD_DIR}"
    
    # Create systemd user service FIRST (before starting containers manually)
    echo "  -> Creating systemd user service..."
    cat > "${USER_SYSTEMD_DIR}/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Podman Compose Database Services
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${COMPOSE_DIR}
ExecStart=/usr/bin/podman-compose -f ${COMPOSE_FILE} up -d
ExecStop=/usr/bin/podman-compose -f ${COMPOSE_FILE} down
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    
    # Enable service for auto-start on boot
    systemctl --user enable "${SERVICE_NAME}.service"
    echo "  -> Service enabled for auto-start on boot"
    
    # Start the service (this will pull images and start containers)
    echo "  -> Starting service via systemctl..."
    systemctl --user start "${SERVICE_NAME}.service"
    
    # Wait for containers to be healthy
    echo "  -> Waiting for containers to become healthy..."
    sleep 10
    
    # Display status
    echo ""
    echo "==> Container Status:"
    cd "${COMPOSE_DIR}"
    podman-compose -f "${COMPOSE_FILE}" ps
    
    echo ""
    echo "==> Database services started successfully!"
    echo "    - MariaDB: localhost:3306 (root password in compose file)"
    echo "    - Redis: localhost:6379 (password in compose file)"
    echo "    - Systemd service: ${SERVICE_NAME}.service (user service)"
}

################################################################################
# Function: prepare_docker_compose_environment
# Description: Prepares the system for database services
################################################################################
prepare_docker_compose_environment() {
    # Create persistent directory for compose files in user's home
    echo "  -> Creating persistent directory at ${COMPOSE_DIR}"
    mkdir -p "${COMPOSE_DIR}"
    
    # Move compose file from temp to persistent location
    if [ -f "${TEMP_COMPOSE_FILE}" ]; then
        echo "  -> Moving compose file to ${COMPOSE_FILE}"
        cp "${TEMP_COMPOSE_FILE}" "${COMPOSE_FILE}"
        chmod 644 "${COMPOSE_FILE}"
    else
        echo "ERROR: Temporary compose file not found at ${TEMP_COMPOSE_FILE}"
        exit 1
    fi
}

################################################################################
# Main
################################################################################

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: This script should NOT be run as root!"
    echo "       Run it as a normal user with sudo privileges"
    exit 1
fi

# Cleanup any existing services first
cleanup_services

# Prepare directories (copy temporary files)
prepare_docker_compose_environment

# Start the database services
start_database_services

echo ""
echo "==> Configuration complete!"
echo "    To check status: systemctl --user status ${SERVICE_NAME}.service"
echo "    To view logs: podman-compose -f ${COMPOSE_FILE} logs -f"
echo "    To cleanup: Run this script with cleanup_services() or systemctl --user stop ${SERVICE_NAME}.service"
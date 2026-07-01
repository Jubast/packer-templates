#!/bin/bash
# Restart any podman containers whose health check is reporting unhealthy.
unhealthy=$(podman ps --filter health=unhealthy --format '{{.Names}}')
for container in ${unhealthy}; do
    echo "$(date --iso-8601=seconds) Restarting unhealthy container: ${container}"
    podman restart "${container}"
done

# Start back up any container that exited despite having an always/unless-stopped
# restart policy (mirrors podman-restart.service, but run periodically instead of
# only at boot, since podman's live restart-policy enforcement is unreliable rootless).
echo "$(date --iso-8601=seconds) Checking for exited containers with a restart policy"
podman start --all --filter restart-policy=always --filter restart-policy=unless-stopped

#!/bin/bash
# Restart any podman containers whose health check is reporting unhealthy.
unhealthy=$(podman ps --filter health=unhealthy --format '{{.Names}}')
for container in ${unhealthy}; do
    echo "$(date --iso-8601=seconds) Restarting unhealthy container: ${container}"
    podman restart "${container}"
done

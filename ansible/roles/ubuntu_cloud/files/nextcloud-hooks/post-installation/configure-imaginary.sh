#!/bin/sh
set -eu

# Configure Nextcloud to use Imaginary for preview generation.
# This hook runs at container start via docker-entrypoint-hooks.d.

run_occ() {
    if [ "$(id -u)" = 0 ]; then
        su -s /bin/sh www-data -c "php /var/www/html/occ $*"
    else
        php /var/www/html/occ "$@"
    fi
}

echo "==> Configuring Imaginary preview service..."

run_occ config:system:set preview_max_x --value="2048" --type=integer
run_occ config:system:set preview_max_y --value="2048" --type=integer
run_occ config:system:set jpeg_quality --value="60" --type=integer
run_occ config:app:set preview jpeg_quality --value="60"
run_occ config:system:set preview_imaginary_url --value="http://169.254.1.2:9000"
run_occ config:system:delete enabledPreviewProviders
run_occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Imaginary"
run_occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\Image"
run_occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\MarkDown"
run_occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\MP3"
run_occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\TXT"
run_occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\OpenDocument"
run_occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\Movie"
run_occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\Krita"
run_occ config:system:set enable_previews --value=true --type=boolean

echo "  -> Imaginary preview service configured."

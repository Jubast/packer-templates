#!/bin/sh
set -eu

# Configure Nextcloud preview generation: Imaginary as the rendering backend,
# and Preview Generator to pre-generate thumbnails in the background.
# This hook runs on every container start (before-starting) via
# docker-entrypoint-hooks.d, so config changes here take effect on redeploy.

run_occ() {
    if [ "$(id -u)" = 0 ]; then
        su -s /bin/sh www-data -c "php /var/www/html/occ $*"
    else
        php /var/www/html/occ "$@"
    fi
}

# Preview Generator sizes must be a power of 4 (64, 256, 1024, 4096, ...) or
# they are silently ignored, and are capped by preview_max_x/preview_max_y.
# squareSizes stays smaller since it's only used for grid/icon thumbnails;
# widthSizes/heightSizes go up to 1024 for gallery/lightbox-sized previews.
# fillWidthHeightSizes/coverWidthHeightSizes back mode=fill/cover requests
# (Viewer, Photos, share previews), which are never issued at icon sizes.
PREVIEW_MAX_X=2048
PREVIEW_MAX_Y=2048
PREVIEW_SQUARE_SIZES="64 256"
PREVIEW_SIZES="64 256 1024"
PREVIEW_FILL_COVER_SIZES="256 1024"

echo "==> Configuring Imaginary preview service..."

run_occ config:system:set preview_max_x --value="${PREVIEW_MAX_X}" --type=integer
run_occ config:system:set preview_max_y --value="${PREVIEW_MAX_Y}" --type=integer
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
run_occ config:system:set enabledPreviewProviders 23 --value="OC\\Preview\\ImaginaryPDF"
run_occ config:system:set enable_previews --value=true --type=boolean

echo "  -> Imaginary preview service configured."

echo "==> Configuring Preview Generator..."

# occ app:install exits 1 if the app is already installed, so guard it
# to keep this hook idempotent across restarts.
if run_occ app:list --output=json | grep -q '"previewgenerator":'; then
    echo "  -> Preview Generator already installed."
else
    run_occ --no-warnings app:install previewgenerator
fi

run_occ config:app:set previewgenerator squareSizes --value="${PREVIEW_SQUARE_SIZES}"
run_occ config:app:set previewgenerator widthSizes --value="${PREVIEW_SIZES}"
run_occ config:app:set previewgenerator heightSizes --value="${PREVIEW_SIZES}"
run_occ config:app:set previewgenerator fillWidthHeightSizes --value="${PREVIEW_FILL_COVER_SIZES}"
run_occ config:app:set previewgenerator coverWidthHeightSizes --value="${PREVIEW_FILL_COVER_SIZES}"
# Keep the default background job enabled (it rides on nextcloud-cron.timer);
run_occ config:app:set previewgenerator job_disabled --value=false --type=boolean
# cap concurrent previews per run at 50, the max Imaginary's -concurrency supports.
run_occ config:app:set previewgenerator job_max_previews --value=50 --type=integer

echo "  -> Preview Generator configured."

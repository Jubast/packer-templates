#!/bin/sh
set -eu

# Configure Nextcloud to use OnlyOffice.
# This hook runs on every container start (before-starting) via
# docker-entrypoint-hooks.d, so config changes here take effect on redeploy.

run_occ() {
    if [ "$(id -u)" = 0 ]; then
        su -s /bin/sh www-data -c "php /var/www/html/occ $*"
    else
        php /var/www/html/occ "$@"
    fi
}

echo "==> Configuring OnlyOffice..."

# occ app:install exits 1 if the app is already installed, so guard it
# to keep this hook idempotent across restarts.
if run_occ app:list --output=json | grep -q '"onlyoffice":'; then
    echo "  -> OnlyOffice already installed."
else
    run_occ --no-warnings app:install onlyoffice
fi

echo "  -> OnlyOffice configured."

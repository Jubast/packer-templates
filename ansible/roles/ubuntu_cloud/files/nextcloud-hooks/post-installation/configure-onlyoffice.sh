#!/bin/sh
set -eu

# Configure Nextcloud to use OnlyOffice.
# This hook runs at container start via docker-entrypoint-hooks.d.

run_occ() {
    if [ "$(id -u)" = 0 ]; then
        su -s /bin/sh www-data -c "php /var/www/html/occ $*"
    else
        php /var/www/html/occ "$@"
    fi
}

echo "==> Configuring OnlyOffice..."

run_occ --no-warnings app:install onlyoffice

echo "  -> OnlyOffice configured."

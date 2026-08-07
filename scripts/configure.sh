#!/bin/bash -e
################################################################################
##  File: configure.sh
##  Desc: Runs Ansible to configure/update existing VMs.
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

cd "$(dirname "$0")/.."

# shellcheck source=lib/keepass-env.sh
source "scripts/lib/keepass-env.sh"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all} --keepass-dbx <path>"
    echo ""
    echo "  $0 configure-cloud      --keepass-dbx <path>  # Configure cloud VM"
    echo "  $0 configure-database   --keepass-dbx <path>  # Configure database VM"
    echo "  $0 configure-gateway    --keepass-dbx <path>  # Configure gateway VM"
    echo "  $0 configure-streaming  --keepass-dbx <path>  # Configure streaming VM"
    echo "  $0 configure-all        --keepass-dbx <path>  # Configure all VMs"
    echo ""
    echo "--keepass-dbx <path> is required — path to the KeePass database holding"
    echo "this repo's secrets (see CLAUDE.md's Secrets section). You'll be prompted"
    echo "for its master password."
    echo ""
    echo "Ansible options are passed through, e.g.:"
    echo "  $0 configure-cloud --keepass-dbx ~/secrets/packer-templates.kdbx --ask-become-pass"
    echo "  $0 configure-cloud --keepass-dbx ~/secrets/packer-templates.kdbx --extra-vars "start_services=true" --ask-become-pass"
    exit 1
fi

COMMAND="$1"
shift

keepass_parse_args "$@"

run_ansible() {
    local playbook="$1"
    cd "./ansible"
    ansible-playbook "playbooks/${playbook}" "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"
}

case "${COMMAND}" in
    configure-cloud)
        echo "==> Configuring cloud VM with Ansible"
        run_ansible "configure-cloud.yml"
        exit 0
        ;;
    configure-database)
        echo "==> Configuring database VM with Ansible"
        run_ansible "configure-database.yml"
        exit 0
        ;;
    configure-gateway)
        echo "==> Configuring gateway VM with Ansible"
        run_ansible "configure-gateway.yml"
        exit 0
        ;;
    configure-streaming)
        echo "==> Configuring streaming VM with Ansible"
        run_ansible "configure-streaming.yml"
        exit 0
        ;;
    configure-all)
        echo "==> Configuring all VMs with Ansible"
        run_ansible "configure-all.yml"
        exit 0
        ;;
    *)
        echo "Invalid command: ${COMMAND}"
        echo "Usage: $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all} --keepass-dbx <path>"
        exit 1
        ;;
esac

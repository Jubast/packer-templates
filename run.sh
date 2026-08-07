#!/bin/bash -e
################################################################################
##  File: run.sh
##  Desc: Runs the packer build to create a vm image, or runs ansible to
##        configure an existing VM.
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
    echo "       $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all} --keepass-dbx <path>"
    echo ""
    echo "Build commands (Packer — creates a new VM template):"
    echo "  $0 build-cloud      --keepass-dbx <path>  # Build cloud VM with Proxmox"
    echo "  $0 build-database   --keepass-dbx <path>  # Build database VM with Proxmox"
    echo "  $0 build-gateway    --keepass-dbx <path>  # Build gateway VM with Proxmox"
    echo "  $0 build-streaming  --keepass-dbx <path>  # Build streaming VM with Proxmox"
    echo ""
    echo "Configure commands (Ansible — apply/update config on existing VMs):"
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

KEEPASS_DBX=""
EXTRA_ARGS=()  # remaining args (minus --keepass-dbx) forwarded to ansible-playbook
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keepass-dbx)
            if [[ $# -lt 2 ]]; then
                echo "Error: --keepass-dbx requires a path argument" >&2
                exit 1
            fi
            KEEPASS_DBX="$2"
            shift 2
            ;;
        --keepass-dbx=*)
            KEEPASS_DBX="${1#--keepass-dbx=}"
            shift
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ -z "${KEEPASS_DBX}" ]]; then
    echo "Error: --keepass-dbx <path> is required (path to the KeePass database)" >&2
    exit 1
fi

export ANSIBLE_KEEPASS_DBX="${KEEPASS_DBX}"

read -r -s -p "KeePass master password: " ANSIBLE_KEEPASS_PSW
echo
export ANSIBLE_KEEPASS_PSW

run_ansible() {
    local playbook="$1"
    cd "./ansible"
    ansible-playbook "playbooks/${playbook}" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
}

case "${COMMAND}" in
    # -------------------------------------------------------------------------
    # Packer build commands
    # -------------------------------------------------------------------------
    build-cloud)
        echo "==> Using builder: proxmox"
        cd "./proxmox/ubuntu-cloud"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-database)
        echo "==> Using builder: proxmox"
        cd "./proxmox/ubuntu-database"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-gateway)
        echo "==> Using builder: proxmox"
        cd "./proxmox/ubuntu-gateway"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-streaming)
        echo "==> Using builder: proxmox"
        cd "./proxmox/ubuntu-streaming"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;

    # -------------------------------------------------------------------------
    # Ansible configure commands
    # -------------------------------------------------------------------------
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
        echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
        echo "       $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all} --keepass-dbx <path>"
        exit 1
        ;;
esac
#!/bin/bash -e
################################################################################
##  File: build.sh
##  Desc: Runs Packer to build a Proxmox VM template.
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

cd "$(dirname "$0")/.."

# shellcheck source=lib/keepass-utils.sh
source "scripts/lib/keepass-utils.sh"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
    echo ""
    echo "  $0 build-cloud      --keepass-dbx <path>  # Build cloud VM with Proxmox"
    echo "  $0 build-database   --keepass-dbx <path>  # Build database VM with Proxmox"
    echo "  $0 build-gateway    --keepass-dbx <path>  # Build gateway VM with Proxmox"
    echo "  $0 build-streaming  --keepass-dbx <path>  # Build streaming VM with Proxmox"
    echo ""
    echo "--keepass-dbx <path> is required — path to the KeePass database holding"
    echo "this repo's secrets. You'll be prompted for its master password."
    exit 1
fi

COMMAND="$1"
shift

KEEPASS_DBX=$(keepass_parse_dbx_arg "$@") || exit 1
KEEPASS_PSW=$(keepass_prompt_password)

build_vm() {
    local vm="$1"
    echo "==> Using builder: proxmox"

    PACKER_PROXMOX_USERNAME=$(keepass_fetch_entry "${KEEPASS_DBX}" "${KEEPASS_PSW}" "shared/proxmox/username") || exit 1
    PACKER_PROXMOX_PASSWORD=$(keepass_fetch_entry "${KEEPASS_DBX}" "${KEEPASS_PSW}" "shared/proxmox/password") || exit 1
    PACKER_USER_USERNAME=$(keepass_fetch_entry "${KEEPASS_DBX}" "${KEEPASS_PSW}" "ubuntu_${vm}/os_user") || exit 1
    PACKER_USER_PASSWORD_ENCRYPTED=$(keepass_fetch_entry "${KEEPASS_DBX}" "${KEEPASS_PSW}" "ubuntu_${vm}/os_user_password_encrypted") || exit 1
    PACKER_USER_SSH_AUTHORIZED_KEYS=$(keepass_fetch_entry "${KEEPASS_DBX}" "${KEEPASS_PSW}" "ubuntu_${vm}/os_user_ssh_authorized_keys") || exit 1

    cd "./packer/proxmox/ubuntu-${vm}"

    packer init .

    export ANSIBLE_KEEPASS_DBX="${KEEPASS_DBX}"
    export ANSIBLE_KEEPASS_PSW="${KEEPASS_PSW}"
    export PACKER_PROXMOX_USERNAME PACKER_PROXMOX_PASSWORD
    export PACKER_USER_USERNAME PACKER_USER_PASSWORD_ENCRYPTED PACKER_USER_SSH_AUTHORIZED_KEYS

    packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .

    unset ANSIBLE_KEEPASS_DBX ANSIBLE_KEEPASS_PSW
    unset PACKER_PROXMOX_USERNAME PACKER_PROXMOX_PASSWORD
    unset PACKER_USER_USERNAME PACKER_USER_PASSWORD_ENCRYPTED PACKER_USER_SSH_AUTHORIZED_KEYS
}

case "${COMMAND}" in
    build-cloud)
        build_vm "cloud"
        exit 0
        ;;
    build-database)
        build_vm "database"
        exit 0
        ;;
    build-gateway)
        build_vm "gateway"
        exit 0
        ;;
    build-streaming)
        build_vm "streaming"
        exit 0
        ;;
    *)
        echo "Invalid command: ${COMMAND}"
        echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
        exit 1
        ;;
esac

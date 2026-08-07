#!/bin/bash -e
################################################################################
##  File: build.sh
##  Desc: Runs Packer to build a Proxmox VM template.
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

cd "$(dirname "$0")/.."

# shellcheck source=lib/keepass-env.sh
source "scripts/lib/keepass-env.sh"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
    echo ""
    echo "  $0 build-cloud      --keepass-dbx <path>  # Build cloud VM with Proxmox"
    echo "  $0 build-database   --keepass-dbx <path>  # Build database VM with Proxmox"
    echo "  $0 build-gateway    --keepass-dbx <path>  # Build gateway VM with Proxmox"
    echo "  $0 build-streaming  --keepass-dbx <path>  # Build streaming VM with Proxmox"
    echo ""
    echo "--keepass-dbx <path> is required — path to the KeePass database holding"
    echo "this repo's secrets (see CLAUDE.md's Secrets section). You'll be prompted"
    echo "for its master password."
    exit 1
fi

COMMAND="$1"
shift

keepass_parse_args "$@"

case "${COMMAND}" in
    build-cloud)
        echo "==> Using builder: proxmox"
        cd "./packer/proxmox/ubuntu-cloud"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-database)
        echo "==> Using builder: proxmox"
        cd "./packer/proxmox/ubuntu-database"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-gateway)
        echo "==> Using builder: proxmox"
        cd "./packer/proxmox/ubuntu-gateway"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-streaming)
        echo "==> Using builder: proxmox"
        cd "./packer/proxmox/ubuntu-streaming"
        packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    *)
        echo "Invalid command: ${COMMAND}"
        echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming} --keepass-dbx <path>"
        exit 1
        ;;
esac

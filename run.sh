#!/bin/bash -e
################################################################################
##  File: run.sh
##  Desc: Runs the packer build to create a vm image
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {build-database|build-gateway|build-home}"
    echo ""
    echo "Examples:"
    echo "  $0 build-database   # Build database VM with Proxmox"
    echo "  $0 build-gateway    # Build gateway VM with Proxmox"
    echo "  $0 build-home       # Build home VM with Proxmox"
    exit 1
fi

COMMAND="$1"

echo "==> Using builder: proxmox"

case "${COMMAND}" in
    build-database)
        cd "./proxmox/ubuntu-database"
        packer build -force -var-file="ubuntu-24.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-gateway)
        cd "./proxmox/ubuntu-gateway"
        packer build -force -var-file="ubuntu-24.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-home)
        cd "./proxmox/ubuntu-home"
        packer build -force -var-file="ubuntu-24.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    *)
        echo "Invalid command: ${COMMAND}"
        echo "Usage: $0 {build-database|build-gateway|build-home}"
        exit 1
        ;;
esac
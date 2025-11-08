#!/bin/bash -e
################################################################################
##  File: run.sh
##  Desc: Runs the packer build to create a vm image
################################################################################

set -e  # Exit on any error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 {qemu|proxmox} {build-database|build-gateway}"
    echo ""
    echo "Examples:"
    echo "  $0 qemu build-database      # Build with QEMU"
    echo "  $0 proxmox build-database   # Build with Proxmox"
    echo "  $0 qemu build-gateway       # Build gateway with QEMU"
    echo "  $0 proxmox build-gateway    # Build gateway with Proxmox"
    exit 1
fi

BUILDER_TYPE="$1"
COMMAND="$2"

# Validate BUILDER_TYPE
if [[ "${BUILDER_TYPE}" != "qemu" && "${BUILDER_TYPE}" != "proxmox" ]]; then
    echo "Error: Builder type must be either 'qemu' or 'proxmox'"
    echo "Usage: $0 {qemu|proxmox} {build-database|build-gateway}"
    exit 1
fi

echo "==> Using builder: ${BUILDER_TYPE}"

case "${COMMAND}" in
    build-database)
        cd "./${BUILDER_TYPE}/ubuntu-database"
        packer build -force -var-file="ubuntu-24.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    build-gateway)
        cd "./${BUILDER_TYPE}/ubuntu-gateway"
        packer build -force -var-file="ubuntu-24.04.auto.pkrvars.hcl" .
        exit 0
        ;;
    *)
        echo "Invalid command: ${COMMAND}"
        echo "Usage: $0 {qemu|proxmox} {build-database|build-gateway}"
        exit 1
        ;;
esac
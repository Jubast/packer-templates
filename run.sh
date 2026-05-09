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
    echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming}"
    echo "       $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all}"
    echo ""
    echo "Build commands (Packer — creates a new VM template):"
    echo "  $0 build-cloud      # Build cloud VM with Proxmox"
    echo "  $0 build-database   # Build database VM with Proxmox"
    echo "  $0 build-gateway    # Build gateway VM with Proxmox"
    echo "  $0 build-streaming  # Build streaming VM with Proxmox"
    echo ""
    echo "Configure commands (Ansible — apply/update config on existing VMs):"
    echo "  $0 configure-cloud      # Configure cloud VM"
    echo "  $0 configure-database   # Configure database VM"
    echo "  $0 configure-gateway    # Configure gateway VM"
    echo "  $0 configure-streaming  # Configure streaming VM"
    echo "  $0 configure-all        # Configure all VMs"
    echo ""
    echo "Ansible options are passed through, e.g.:"
    echo "  $0 configure-cloud --ask-become-pass"
    echo "  $0 configure-cloud --tags firewall"
    exit 1
fi

COMMAND="$1"
shift
EXTRA_ARGS=("$@")  # remaining args forwarded to ansible-playbook

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
        echo "==> Configuring home VM with Ansible"
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
        echo "Usage: $0 {build-cloud|build-database|build-gateway|build-streaming}"
        echo "       $0 {configure-cloud|configure-database|configure-gateway|configure-streaming|configure-all}"
        exit 1
        ;;
esac
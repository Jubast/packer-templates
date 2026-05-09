# packer-templates

Infrastructure-as-code for a Proxmox homelab. Packer builds Ubuntu 26.04 VM templates; Ansible configures them. All services run as rootless [Podman](https://podman.io/) containers managed by systemd user units.

## VMs

| VM | Services |
|----|---------|
| **ubuntu-cloud** | [Nextcloud](https://nextcloud.com/), [OnlyOffice](https://www.onlyoffice.com/), [Vaultwarden](https://github.com/dani-garcia/vaultwarden) |
| **ubuntu-database** | [MariaDB](https://mariadb.org/), [Redis](https://redis.io/), [RabbitMQ](https://www.rabbitmq.com/) |
| **ubuntu-gateway** | [Nginx Proxy Manager](https://nginxproxymanager.com/), [AdGuard Home](https://adguard.com/en/adguard-home/overview.html), [ddclient](https://ddclient.net/) (Cloudflare DDNS), [WireGuard](https://www.wireguard.com/) |
| **ubuntu-streaming** | [Jellyfin](https://jellyfin.org/), [qBittorrent](https://www.qbittorrent.org/), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/), [Bazarr](https://www.bazarr.media/), [Jellyseerr](https://github.com/Fallenbagel/jellyseerr) |

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer) ≥ 1.9
- [Ansible](https://docs.ansible.com/) ≥ 2.15
- A running [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) node

## Usage

All commands are run via `run.sh` from the repo root.

### 1. Build a VM template (Packer)

Copy the sample vars file and fill in your Proxmox connection details, storage pool, and desired VM settings:

```bash
cp proxmox/ubuntu-cloud/ubuntu-26.04.sample.pkrvars.hcl proxmox/ubuntu-cloud/ubuntu-26.04.auto.pkrvars.hcl
# edit ubuntu-26.04.auto.pkrvars.hcl
```

Then build:

```bash
./run.sh build-cloud
./run.sh build-database
./run.sh build-gateway
./run.sh build-streaming
```

### 2. Configure inventory (Ansible)

```bash
cp ansible/inventory/sample.yml ansible/inventory/hosts.yml
# edit hosts.yml — set IP addresses and ansible_user per VM
```

Copy and populate the group variable files:

```bash
cp ansible/inventory/group_vars/ubuntu_cloud/a_sample.yml \
   ansible/inventory/group_vars/ubuntu_cloud/main.yml
# repeat for ubuntu_database, ubuntu_gateway, ubuntu_streaming
```

### 3. Configure VMs (Ansible)

```bash
./run.sh configure-cloud
./run.sh configure-database
./run.sh configure-gateway
./run.sh configure-streaming
./run.sh configure-all        # all VMs at once
```

Extra arguments are forwarded to `ansible-playbook`:

```bash
./run.sh configure-cloud --ask-become-pass
./run.sh configure-streaming --extra-vars "start_services=true" --ask-become-pass
```

## Repository structure

```
run.sh                        # entry point for all build/configure commands
proxmox/
  ubuntu-{cloud,database,gateway,streaming}/
    variables.pkr.hcl         # variable declarations
    ubuntu-26.04.pkr.hcl      # Packer build definition
    ubuntu-26.04.sample.pkrvars.hcl
    ubuntu-26.04.auto.pkrvars.hcl   # your values (gitignored)
    cloud-init/               # cloud-init user-data template + meta-data
ansible/
  inventory/
    hosts.yml                 # your inventory (gitignored)
    group_vars/
      ubuntu_cloud/main.yml   # service-specific variables
      ubuntu_database/main.yml
      ubuntu_gateway/main.yml
      ubuntu_streaming/main.yml
  playbooks/                  # one playbook per VM group + configure-all
  roles/
    common/                   # base packages, Podman, healthcheck timer
    common_after/             # post-role cleanup / image pruning
    ubuntu_cloud/
    ubuntu_database/
    ubuntu_gateway/
    ubuntu_streaming/
```

## Notes

- All containers use `network_mode: pasta` (rootless userspace networking — no `--privileged`, no host-network).
- Container services are deployed as systemd user units and start automatically on boot via `loginctl enable-linger`.
- A systemd timer runs a container healthcheck and prunes unused images periodically.

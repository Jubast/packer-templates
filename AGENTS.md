# AGENTS

This document provides guidance for AI coding agents working on this repository.

## Project Overview
This repository uses Packer and Ansible to build and configure linux (mainly Ubuntu 26.04) VMs on Proxmox.
Runtime services are containerized with rootless Podman and managed by systemd user units.

## Shared Rules
- Never run [run.sh](run.sh) from an agent context. It can execute actions on a real system.
- Use direct CLI commands instead: packer and ansible-playbook.
- Keep suggestions aligned with rootless Podman patterns already used in this repo.
- Prefer validation before destructive or long-running commands.
- Do not view and/or edit gitignored secret-like files unless explicitly asked:
  - ansible/inventory/hosts.yml
  - proxmox/*/ubuntu-26.04.auto.pkrvars.hcl

## Cross-Component Consistency
- Keep Proxmox templates, Ansible configuration, and [run.sh](run.sh) behavior in sync.
- If one part changes, update all related parts so build/configure workflows still work end-to-end.
- When adding, removing, or renaming a VM, update matching paths and naming in proxmox/, ansible/playbooks, ansible/roles, ansible/inventory/group_vars, and [run.sh](run.sh).
- When command names or targets change, update command handling and usage text in [run.sh](run.sh), plus any documentation that lists supported commands.
- When variable names, file names, or folder names change, update all references across Packer files, Ansible files, and templates to avoid broken links between components.

## Podman and Podman Compose Guidance
- Keep compose files aligned with the current rootless networking default: network_mode: pasta.
- Keep compose schema explicit (version: '3') unless a planned migration requires a different version.
- Pin image versions to explicit tags. Do not use latest.
- Keep restart policy explicit (currently unless-stopped) for long-running services.
- Define healthchecks for services whenever possible, with practical intervals/timeouts/start periods.
- Define resource limits for each service (CPU and memory). Add resource reservations when needed for critical baseline capacity.
- Keep resource values realistic for the target VM profile and service role.
- Keep storage explicit:
  - use named volumes for persistent app data,
  - use bind mounts only when host paths are intentionally required,
  - keep read-only mounts read-only when possible.
- Keep port mappings explicit and minimal; only expose ports that are required.
- Keep user and namespace settings explicit when needed by the image (for example userns_mode: keep-id or PUID/PGID environment values).
- Preserve Podman-specific behavior already used in this repo (for example x-podman settings) unless there is a clear reason to change it.
- When changing compose defaults, verify related env files, templates, handlers, and service units still match the updated compose behavior.

## Ansible Role Folder Naming
- Role folder names must be lowercase with underscores only.
- Shared roles remain generic and stable: common, common_after.
- VM-specific roles map to inventory groups using underscores:
  - ansible/roles/ubuntu_cloud
  - ansible/roles/ubuntu_database
  - ansible/roles/ubuntu_gateway
  - ansible/roles/ubuntu_streaming
- Do not use hyphens in role folder names.
- Keep role internals in standard layout when present: defaults/, tasks/, handlers/, templates/, files/.

## Code Quality and Linting
- Keep changes small, idempotent, and consistent with existing YAML/HCL style.
- Run validation before proposing apply/build commands.
- Prefer lint/syntax checks after edits when tools are available:
  - cd ansible && ansible-playbook --syntax-check playbooks/configure-<target>.yml
  - cd ansible && ansible-lint playbooks/configure-<target>.yml
  - cd ansible && yamllint .
  - cd proxmox/ubuntu-<vm> && packer fmt -check . && packer validate -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
- If lint findings conflict with established project patterns, preserve project conventions and document the rationale.

## Testing
- Agent testing is limited to linting, syntax checks, validation commands, and dry runs.
- Do not perform real-system tests from agents.
- Allowed verification commands include:
  - cd ansible && ansible-playbook --syntax-check playbooks/configure-<target>.yml
  - cd ansible && ansible-playbook --check --diff playbooks/configure-<target>.yml
  - cd ansible && ansible-lint playbooks/configure-<target>.yml
  - cd ansible && yamllint .
  - cd proxmox/ubuntu-<vm> && packer fmt -check . && packer validate -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
- Once changes are verified and good enough, ask the developer to run the real-system implementation test.

## Agent: Packer
Purpose: Build and refine Ubuntu VM templates for Proxmox.

Scope:
- proxmox/ubuntu-cloud/**
- proxmox/ubuntu-database/**
- proxmox/ubuntu-gateway/**
- proxmox/ubuntu-streaming/**

Rules:
- Preserve naming and layout conventions around ubuntu-26.04.pkr.hcl and variables.pkr.hcl.
- Treat *.sample.pkrvars.hcl as templates; avoid writing secrets into tracked files.
- Validate before build when changing template logic:
  - cd proxmox/ubuntu-<vm> && packer validate -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
- Build only when explicitly requested:
  - cd proxmox/ubuntu-cloud && packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
  - cd proxmox/ubuntu-database && packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
  - cd proxmox/ubuntu-gateway && packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .
  - cd proxmox/ubuntu-streaming && packer build -force -var-file="ubuntu-26.04.auto.pkrvars.hcl" .

## Agent: Ansible
Purpose: Configure VM roles/playbooks and service deployment safely.

Scope:
- ansible/playbooks/**
- ansible/roles/**
- ansible/inventory/**

Rules:
- Keep playbook naming consistent with configure-<target>.yml patterns.
- Respect role structure (defaults/tasks/handlers/templates/files) and existing variable names.
- Preserve variable layering model:
  - ansible/inventory/group_vars/all.yml
  - ansible/inventory/group_vars/ubuntu_*/main.yml
- Assume sample files are copied first (a_sample.yml -> main.yml, sample.yml -> hosts.yml).
- Validate syntax before broad changes when possible:
  - cd ansible && ansible-playbook --syntax-check playbooks/configure-<target>.yml
- Prefer dry runs before apply when possible:
  - cd ansible && ansible-playbook --check --diff playbooks/configure-<target>.yml
- Apply only when explicitly requested:
  - cd ansible && ansible-playbook playbooks/configure-cloud.yml
  - cd ansible && ansible-playbook playbooks/configure-database.yml
  - cd ansible && ansible-playbook playbooks/configure-gateway.yml
  - cd ansible && ansible-playbook playbooks/configure-streaming.yml
  - cd ansible && ansible-playbook playbooks/configure-all.yml

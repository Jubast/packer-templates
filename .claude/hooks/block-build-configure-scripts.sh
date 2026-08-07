#!/usr/bin/env bash
# PreToolUse(Bash) guard: refuse to execute scripts/build.sh or
# scripts/configure.sh from an agent context.
# CLAUDE.md: these scripts trigger real Packer builds and Ansible applies
# against a live Proxmox host/VMs, so agents must use the direct
# packer/ansible-playbook commands instead.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')

pattern='(^|[;&|]|&&|\|\|)[[:space:]]*(bash[[:space:]]+|sh[[:space:]]+|source[[:space:]]+|\.[[:space:]]+)?([^[:space:];&|]*/)?scripts/(build|configure)\.sh([[:space:]]|$)'

if [[ "$cmd" =~ $pattern ]]; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by .claude/hooks/block-build-configure-scripts.sh: scripts/build.sh and scripts/configure.sh must never be executed by an agent (see CLAUDE.md) — they run real Packer builds and Ansible applies against a live Proxmox host/VMs. Use the direct packer/ansible-playbook commands from CLAUDE.md instead."}}
EOF
fi

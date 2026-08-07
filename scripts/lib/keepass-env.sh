#!/bin/bash
################################################################################
##  File: lib/keepass-env.sh
##  Desc: Shared by build.sh and configure.sh. Parses --keepass-dbx <path> out
##        of the caller's remaining args, prompts for the master password, and
##        exports ANSIBLE_KEEPASS_DBX / ANSIBLE_KEEPASS_PSW for the KeePass
##        Ansible lookup plugin (see CLAUDE.md's Secrets section).
##        Meant to be sourced, not executed directly.
################################################################################

keepass_parse_args() {
    KEEPASS_DBX=""
    REMAINING_ARGS=()
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
                REMAINING_ARGS+=("$1")
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
}

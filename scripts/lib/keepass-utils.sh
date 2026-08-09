#!/bin/bash
################################################################################
##  File: lib/keepass-utils.sh
##  Desc: Shared by build.sh and configure.sh. KeePass arg-parsing, password
##        prompt, and entry-fetch helpers. Every function returns its result
##        via stdout only — nothing is set in the caller's environment.
##        Meant to be sourced, not executed directly.
################################################################################

# Extracts --keepass-dbx <path> from the given args and prints it to stdout.
# Exits 1 with an error on stderr if it's missing.
#
# Usage: dbx=$(keepass_parse_dbx_arg "$@")
keepass_parse_dbx_arg() {
    local dbx=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --keepass-dbx)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --keepass-dbx requires a path argument" >&2
                    exit 1
                fi
                dbx="$2"
                shift 2
                ;;
            --keepass-dbx=*)
                dbx="${1#--keepass-dbx=}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ -z "${dbx}" ]]; then
        echo "Error: --keepass-dbx <path> is required (path to the KeePass database)" >&2
        exit 1
    fi

    printf '%s\n' "${dbx}"
}

# Prompts for the KeePass master password and prints it to stdout.
#
# Usage: psw=$(keepass_prompt_password)
keepass_prompt_password() {
    local psw
    read -r -s -p "KeePass master password: " psw
    echo >&2
    printf '%s\n' "${psw}"
}

# Fetches one KeePass entry's password field and prints it to stdout.
#
# Usage: value=$(keepass_fetch_entry <dbx-path> <master-password> <entry-path>)
keepass_fetch_entry() {
    local dbx="$1" psw="$2" entry_path="$3"

    export ANSIBLE_KEEPASS_PSW="${psw}"
    python3 \
        "$(dirname "${BASH_SOURCE[0]}")/keepass_fetch_entry.py" \
        "${dbx}" "${entry_path}"
    local status=$?
    unset ANSIBLE_KEEPASS_PSW
    return $status
}

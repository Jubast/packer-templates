#!/usr/bin/env python3
"""
Fetch a single KeePass entry's password field value and print it to stdout.

Usage: keepass_fetch_entry.py <kdbx-path> <entry-path>
  <entry-path> uses the same "group/.../entry-title" convention as the
  viczem.keepass.keepass Ansible lookup plugin, e.g. "ubuntu_cloud/os_user".

Reads the master password from the ANSIBLE_KEEPASS_PSW environment variable —
never as a CLI argument, which would leak it into `ps`/shell history.
"""
import os
import sys

from pykeepass import PyKeePass
from pykeepass.exceptions import CredentialsError


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <kdbx-path> <entry-path>", file=sys.stderr)
        sys.exit(1)

    dbx, entry_path = sys.argv[1], sys.argv[2]

    psw = os.environ.get("ANSIBLE_KEEPASS_PSW")
    if not psw:
        print("Error: ANSIBLE_KEEPASS_PSW is not set.", file=sys.stderr)
        sys.exit(1)

    try:
        kp = PyKeePass(dbx, password=psw)
    except CredentialsError:
        print("Error: wrong KeePass master password.", file=sys.stderr)
        sys.exit(1)

    entry = kp.find_entries_by_path(entry_path.split("/"), first=True)
    if entry is None:
        print(f"Error: KeePass entry '{entry_path}' not found.", file=sys.stderr)
        sys.exit(1)

    value = kp.deref(entry.password) if entry.password else entry.password
    if not value:
        print(f"Error: KeePass entry '{entry_path}' has no password value.", file=sys.stderr)
        sys.exit(1)

    print(value)


if __name__ == "__main__":
    main()

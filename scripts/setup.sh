#!/bin/bash

set -e

cd "$(dirname "$0")/.."

pipx install --force --python python3 ansible-lint yamllint

cd ansible

ansible-galaxy collection install -r requirements.yml
 
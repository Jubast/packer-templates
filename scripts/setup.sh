#!/bin/bash

set -e

mkdir -p "$(dirname "$0")/.."
cd "$(dirname "$0")/.."

pipx install --force --python python3 ansible-lint yamllint

# install pykeepass in ansible-core venv
pipx runpip ansible-core install 'pykeepass==4.0.3'

cd ansible

ansible-galaxy collection install -r requirements.yml
 
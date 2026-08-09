#!/bin/bash

set -e

mkdir -p "$(dirname "$0")/.."
cd "$(dirname "$0")/.."

# install pykeepass in ansible-core venv
pipx install --force --python python3 ansible-lint yamllint
pipx runpip ansible-core install 'pykeepass==4.0.3'

# install pykeepass in the system
python3 -m pip install --break-system-packages pykeepass==4.0.3

cd ansible

ansible-galaxy collection install -r requirements.yml
 
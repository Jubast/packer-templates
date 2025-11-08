#cloud-config
#https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html
autoinstall:
  version: 1

  #############
  # CORE
  #############

  # update installer
  refresh-installer:
    update: true
    channel: latest/edge

  # configure keyboard layout
  keyboard:
    layout: us

  # configure locale
  locale: "en_US.UTF-8"

  # configure timezone
  timezone: "Etc/UTC"

  # configure system
  user-data:
    # configure hostname
    hostname: ubuntu-database
    # configure user
    users:
      - name: ${user_username}
        passwd: ${user_password_encrypted}
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: [adm, users, sudo]
        shell: /bin/bash
        lock_passwd: false
        ssh_authorized_keys:
          - ${user_ssh_authorized_keys}

  # network configuration (automatic config [DHCP on interfaces named eth* or en*])
  #network:

  # storage configuration
  storage:
    # use lvm and use entire disk
    layout:
      name: lvm
      sizing-policy: all
    # disable swap, don't burn out ssd disks
    swap:
      size: 0

  #############
  # UBUNTU CONFIGURATION
  #############

  # disable codecs, which means not installing the ubuntu-restricted-addons (flash player, etc..) package
  codecs:
    install: false

  # disable OEM (pc company bloatware) meta-package automatic installation
  oem:
    install: false

  # install drivers as suggested by `ubuntu-drivers`.
  drivers:
    install: true

  # enable ssh
  ssh:
    install-server: true
    allow-pw: false

  # after install update the system with security and update packages
  updates: all  

  # disable SSH root login and start the ufw firewall automatically
  debconf-selections: |
    openssh-server openssh-server/permit-root-login boolean false
    ufw ufw/allow_known_ports multiselect SSH
    ufw ufw/enable boolean true
    debconf debconf/frontend select Noninteractive

  # install additional packages
  packages:
    - qemu-guest-agent

  # shutdown instead of reboot
  shutdown: reboot
# PACKER
ssh_private_key_file        = "~/path/to/.ssh/id_ed25519"

# Proxmox Connection
proxmox_url                 = "https://127.0.0.1:8006/api2/json"
proxmox_username            = "myNonRootUserWithPermissions@pam"
proxmox_password            = "mySecurePassword"
proxmox_node                = "pve-01"

# Proxmox Storage
storage_pool                = "local-lvm"

# Proxmox Network
network_bridge              = "vmbr0"

# ISO
iso_storage_pool            = "local"
iso_url                     = "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso"
iso_checksum                = "sha256:dec49008a71f6098d0bcfc822021f4d042d5f2db279e4d75bdd981304f1ca5d9"

# VM
os_name                     = "Ubuntu 26.04 LTS (Resolute Raccoon)"
vm_name                     = "ubuntu26-cloud"
vm_id                       = 204

# USER
user_username               = "cloud"
user_password_encrypted     = "$6$rounds=4096$4dXBB/1clk96jqRj$2kQWrFitmdolntPRiFx5hN8JCAckGiQd.BjLbaFPn2YwZ3f9UIYAXy8iWb7LKwx.aQjVbwuhIOVzWiQ2RijSN."
user_ssh_authorized_keys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHLW9aa+K37B5YLqONk9ayKEC5OwjtqG78AwT6YKezR your_email@example.com"


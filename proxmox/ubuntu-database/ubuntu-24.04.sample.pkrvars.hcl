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
iso_url                     = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
iso_checksum                = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"

# VM
os_name                     = "Ubuntu 24.04 LTS (Noble Numbat)"
vm_name                     = "ubuntu24-database"
vm_id                       = 201

# USER
user_username               = "database"
user_password_encrypted     = "$6$rounds=4096$4dXBB/1clk96jqRj$2kQWrFitmdolntPRiFx5hN8JCAckGiQd.BjLbaFPn2YwZ3f9UIYAXy8iWb7LKwx.aQjVbwuhIOVzWiQ2RijSN."
user_ssh_authorized_keys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHLW9aa+K37B5YLqONk9ayKEC5OwjtqG78AwT6YKezR your_email@example.com"

# DATABASES
database_mariadb_root_password  = "ChangeMeToAStrongPassword123!"
database_redis_password         = "ChangeMeToAStrongPassword123!"
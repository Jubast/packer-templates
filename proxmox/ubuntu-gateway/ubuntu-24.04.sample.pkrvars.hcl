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
vm_name                     = "ubuntu24-gateway"
vm_id                       = 202

# USER
user_username               = "myUser"
user_password_encrypted     = "$6$rounds=4096$4dXBB/1clk96jqRj$2kQWrFitmdolntPRiFx5hN8JCAckGiQd.BjLbaFPn2YwZ3f9UIYAXy8iWb7LKwx.aQjVbwuhIOVzWiQ2RijSN."
user_ssh_authorized_keys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHLW9aa+K37B5YLqONk9ayKEC5OwjtqG78AwT6YKezR your_email@example.com"

# NGINX PROXY MANAGER DATABASE
npm_db_mysql_host                           = "192.168.1.254"
npm_db_mysql_port                           = 3306
npm_db_mysql_user                           = "npm"
npm_db_mysql_password                       = "mySecureNpmDbPassword"
npm_db_mysql_name                           = "npm"

# WIREGUARD
wireguard_server_network_interface          = "eth0"
wireguard_server_address_ipv4               = "10.10.0.1"
wireguard_server_subnet_address_ipv4        = "10.10.0.0"
wireguard_server_listen_port                = 51820
wireguard_server_private_key                = "base64_encoded_private_key_goes_here"
wireguard_server_public_key                 = "base64_encoded_public_key_goes_here"
wireguard_peers                             = [
    {
        name              = "client-1"
        private_key       = "base64_encoded_private_key_goes_here"
        public_key        = "base64_encoded_public_key_goes_here"
        preshared_key     = "base64_encoded_preshared_key_goes_here"
        address_ipv4      = "10.10.0.2"
    }
]

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
vm_name                     = "ubuntu24-cloud"
vm_id                       = 204

# USER
user_username               = "cloud"
user_password_encrypted     = "$6$rounds=4096$4dXBB/1clk96jqRj$2kQWrFitmdolntPRiFx5hN8JCAckGiQd.BjLbaFPn2YwZ3f9UIYAXy8iWb7LKwx.aQjVbwuhIOVzWiQ2RijSN."
user_ssh_authorized_keys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHLW9aa+K37B5YLqONk9ayKEC5OwjtqG78AwT6YKezR your_email@example.com"

# CLOUD SERVICES
cloud_nextcloud_db_host         = "192.168.1.x"   # IP or hostname of ubuntu-database
cloud_nextcloud_db_name         = "nextcloud"
cloud_nextcloud_db_user         = "nextcloud"
cloud_nextcloud_db_password     = "ChangeMeToAStrongPassword123!"
cloud_nextcloud_redis_password  = "ChangeMeToAStrongPassword123!"   # must match database_redis_password on ubuntu-database
cloud_nextcloud_admin_password  = "ChangeMeToAStrongPassword123!"
cloud_nextcloud_trusted_proxies        = "127.0.0.1"
cloud_nextcloud_trusted_domains        = "localhost"
cloud_onlyoffice_jwt_secret            = "ChangeMeToAStrongRandomSecret123!"   # must match cloud_nextcloud_onlyoffice_jwt_secret
cloud_onlyoffice_db_host               = "192.168.1.x"   # IP or hostname of the database server for OnlyOffice
cloud_onlyoffice_db_name               = "onlyoffice"
cloud_onlyoffice_db_user               = "onlyoffice"
cloud_onlyoffice_db_password           = "ChangeMeToAStrongPassword123!"
cloud_onlyoffice_redis_host            = "192.168.1.x"   # IP or hostname of the Redis server for OnlyOffice
cloud_onlyoffice_redis_user            = ""
cloud_onlyoffice_redis_pass            = "ChangeMeToAStrongPassword123!"
cloud_onlyoffice_redis_db              = "1"
cloud_onlyoffice_amqp_uri              = "amqp://admin:ChangeMeToAStrongPassword123!@192.168.1.x:5672/"   # RabbitMQ URI for OnlyOffice
cloud_vaultwarden_admin_token          = "ChangeMeToAStrongRandomToken123!"

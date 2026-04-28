// PACKER
variable "ssh_private_key_file" {
  type = string
  description = "Path to the SSH private key file for Packer to connect to the VM."
}

// PROXMOX
variable "proxmox_url" {
  type = string
  description = "The URL for the Proxmox API."
}

variable "proxmox_username" {
  type = string
  description = "The username to authenticate with Proxmox."
}

variable "proxmox_password" {
  type = string
  description = "The password to authenticate with Proxmox."
  sensitive = true
}

variable "proxmox_node" {
  type = string
  description = "The Proxmox node to build on."
}

// STORAGE
variable "storage_pool" {
  type = string
  description = "The storage pool where the VM disk will be created."
}

// NETWORK
variable "network_bridge" {
  type = string
  description = "The network bridge to use for the VM."
}

// ISO
variable "iso_storage_pool" {
  type = string
  description = "The storage pool where ISOs are stored."
}

variable "iso_url" {
  type = string
  description = "URL for the ISO to download."
}

variable "iso_checksum" {
  type = string
  description = "The checksum for the ISO file."
}

// VM
variable "os_name" {
  type = string
  description = "Name and version of the guest operating system."
}

variable "vm_name" {
  type = string
  description = "Name of the new VM to create."
}

variable "vm_id" {
  type = number
  description = "The ID for the VM template."
}

// USER
variable "user_username" {
  type = string
  description = "The username for the operating system."
}

variable "user_password_encrypted" {
  type = string
  description = "The encrypted password to login to the operating system."
  sensitive = true
}

variable "user_ssh_authorized_keys" {
  type = string
  description = "The SSH authorized keys for the user."
}

// CLOUD SERVICES
variable "cloud_nextcloud_db_host" {
  type = string
  description = "Hostname or IP of the ubuntu-database server (provides MariaDB and Redis for Nextcloud)."
}

variable "cloud_nextcloud_db_name" {
  type = string
  description = "The MariaDB database name for Nextcloud."
}

variable "cloud_nextcloud_db_user" {
  type = string
  description = "The MariaDB username for Nextcloud."
}

variable "cloud_nextcloud_db_password" {
  type = string
  description = "The MariaDB password for the Nextcloud database user."
  sensitive = true
}

variable "cloud_nextcloud_redis_password" {
  type = string
  description = "The Redis password from ubuntu-database (matches database_redis_password on that host)."
  sensitive = true
}

variable "cloud_nextcloud_admin_password" {
  type = string
  description = "The initial admin password for the Nextcloud web interface."
  sensitive = true
}

variable "cloud_nextcloud_trusted_proxies" {
  type = string
  description = "The trusted proxies for the nexcloud web interface."
}

variable "cloud_nextcloud_trusted_domains" {
  type = string
  description = "The trusted domains for the nexcloud web interface."
}

variable "cloud_onlyoffice_jwt_secret" {
  type = string
  description = "The JWT secret used by OnlyOffice Document Server and the Nextcloud OnlyOffice app."
  sensitive = true
}

variable "cloud_onlyoffice_db_host" {
  type = string
  description = "Hostname or IP of the database server for OnlyOffice."
}

variable "cloud_onlyoffice_db_name" {
  type = string
  description = "The MariaDB database name for OnlyOffice."
}

variable "cloud_onlyoffice_db_user" {
  type = string
  description = "The MariaDB username for OnlyOffice."
}

variable "cloud_onlyoffice_db_password" {
  type = string
  description = "The MariaDB password for the OnlyOffice database user."
  sensitive = true
}

variable "cloud_onlyoffice_redis_host" {
  type = string
  description = "Hostname or IP of the Redis server for OnlyOffice."
}

variable "cloud_onlyoffice_redis_user" {
  type = string
  description = "The Redis username for OnlyOffice."
}

variable "cloud_onlyoffice_redis_pass" {
  type = string
  description = "The Redis password for OnlyOffice."
  sensitive = true
}

variable "cloud_onlyoffice_redis_db" {
  type = string
  description = "The Redis database index for OnlyOffice."
}

variable "cloud_onlyoffice_amqp_uri" {
  type = string
  description = "The AMQP URI for the RabbitMQ broker used by OnlyOffice (e.g. amqp://user:password@host:5672/)."
  sensitive = true
}

variable "cloud_vaultwarden_admin_token" {
  type = string
  description = "The admin token for the Vaultwarden admin panel (/admin)."
  sensitive = true
}

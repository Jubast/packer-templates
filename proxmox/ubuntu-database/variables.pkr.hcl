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
}

variable "user_ssh_authorized_keys" {
  type = string
  description = "The SSH authorized keys for the user."
}

// DATABASE
variable "database_mariadb_root_password" {
  type = string
  description = "The root password for the MariaDB database."
}

variable "database_redis_password" {
  type = string
  description = "The password for the Redis database."
}
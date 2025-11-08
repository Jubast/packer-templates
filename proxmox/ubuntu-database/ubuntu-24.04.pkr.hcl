packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.2"
    }
  }
}

locals {
  build_date = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  vm_notes = "OS: ${var.os_name} (build on: ${local.build_date})"
  http_content = {
    "/meta-data" = "${file("${path.root}/cloud-init/meta-data")}"
    "/user-data" = templatefile("${path.root}/cloud-init/user-data.pkrtpl.hcl", {
      user_username             = var.user_username
      user_password_encrypted   = var.user_password_encrypted
      user_ssh_authorized_keys  = var.user_ssh_authorized_keys
    })
  }
}

source "proxmox-iso" "ubuntu-database" {   
    # Proxmox connection settings
    proxmox_url              = var.proxmox_url
    username                 = var.proxmox_username
    password                 = var.proxmox_password
    node                     = var.proxmox_node
    insecure_skip_tls_verify = true

    # VM General Settings
    vm_name                  = var.vm_name
    vm_id                    = var.vm_id
    template_description     = local.vm_notes

    # VM ISO Install Settings
    boot_iso {
      iso_url                  = var.iso_url
      iso_checksum             = var.iso_checksum
      iso_storage_pool         = var.iso_storage_pool
      unmount              = true
    }

    # VM System Settings
    qemu_agent               = true

    # VM Hard Disk Settings
    scsi_controller          = "virtio-scsi-single"
    disks {
        disk_size            = "64G"
        storage_pool         = var.storage_pool
        type                 = "scsi"
        format               = "raw"
        io_thread            = true
        discard              = true
    }

    # VM CPU Settings
    cores                    = 2
    sockets                  = 1
    cpu_type                 = "x86-64-v2-AES"

    # VM Memory Settings
    memory                   = 2048

    # VM Network Settings
    network_adapters {
        model                = "virtio"
        bridge               = var.network_bridge
        firewall             = false
    }

    # VM Display Settings
    vga {
      type = "std"
    }

    # TPM
    tpm_config {
      tpm_storage_pool = var.storage_pool
      tpm_version      = "v2.0"
    }

    # VM Cloud-Init Settings
    http_content             = local.http_content

    # Boot and Provisioning Settings
    boot_command             = ["e<wait><down><down><down><end> autoinstall 'ds=nocloud;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<F10>"]    
    boot_wait                = "5s"

    # Communicator Settings
    communicator             = "ssh"
    ssh_username             = var.user_username
    ssh_private_key_file     = var.ssh_private_key_file
    ssh_timeout              = "20m"
}

build {
    sources = [ "sources.proxmox-iso.ubuntu-database" ]

    # wait for cloud-init to successfully finish
    provisioner "shell" {
      inline = [
        "cloud-init status --wait > /dev/null 2>&1"
      ]
    }

    provisioner "shell" {      
      execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
      script          = "${path.root}/scripts/configure-system.sh"
    }

    provisioner "shell" {      
      execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
      script          = "${path.root}/scripts/install-container-tools.sh"
    }

    provisioner "shell" {
      environment_vars = ["FOR_USER=${var.user_username}"]
      execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
      script          = "${path.root}/scripts/enable-user-lingering.sh"
    }

    provisioner "shell" {
      inline = ["mkdir -p /tmp/docker"]
    }

    provisioner "file" {
      destination = "/tmp/docker/databases-docker-compose.yml"
      content     = templatefile("${path.root}/assets/docker/databases-docker-compose.yml.pkrtpl.hcl", {
        database_mariadb_root_password      = var.database_mariadb_root_password
        database_redis_password             = var.database_redis_password
      })
    }

    provisioner "shell" {
      execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
      script          = "${path.root}/scripts/configure-container-services.sh"
    }
}
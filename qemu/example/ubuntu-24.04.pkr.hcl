packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.1.0"
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

source "qemu" "basic-example" {   
    vm_name = "${var.vm_name}"
    cpus = "2"
    memory = "2048"
    disk_size = "16G"

    accelerator             = "kvm"
    format                  = "qcow2"
    net_device              = "virtio-net"
    disk_interface          = "virtio"

    iso_url                 = var.iso_url
    iso_checksum            = var.iso_checksum
    http_content            = local.http_content

    boot_command            = ["e<wait><down><down><down><end> autoinstall 'ds=nocloud;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<F10>"]    
    boot_wait               = "5s"

    shutdown_command        = "sudo shutdown -P now"

    communicator            = "ssh"
    ssh_username            = var.user_username
    ssh_private_key_file    = var.ssh_private_key_file
    ssh_timeout             = "15m"    

    output_directory        = "output"
}

build {
    sources = [ "sources.qemu.example" ]

    # wait for cloud-init to successfully finish
    provisioner "shell" {
      inline = [
        "cloud-init status --wait > /dev/null 2>&1"
      ]
    }
}
# docs https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container
# To import as existing LXC container:
##   terraform import proxmox_virtual_environment_container.gitlab-runner pve/107

resource "proxmox_virtual_environment_container" "gitlab-runner" {
  description = null
  tags = ["dev", "tf"]
  node_name = "pve"
  vm_id     = 107
  unprivileged = true
  features {
    nesting = true
  }
  console {
    enabled = true
    type = "tty"
    tty_count = 2
  }
  initialization {
    hostname = "gitlab-runner"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
       address = "auto" 
      }
    }
    dns {
      servers = [ "10.10.110.2"]
    }
  }

  memory {
    dedicated = 1024
    swap      = 512  
  }
  disk {
    datastore_id = "local-lvm"
    size         = 12
  }
    network_interface {
    firewall = true
    mac_address = "AA:BB:CC:DD:EE:FF"
    name = "eth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.ubuntu-24-04-standard_amd64.id 
    # ^ LXC template file. See ubuntu24-lxc.tf for file resource. Ensure you have the template uploaded to Proxmox first.
    type             = "ubuntu"
  }
}

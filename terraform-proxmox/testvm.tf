# docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
# To import as existing VM:
##    terraform import proxmox_virtual_environment_vm.testVM1 pve/221
resource "proxmox_virtual_environment_vm" "testVM1" {
  name        = "testVM1"
  description = "Test VM 1 - ubuntu 24.04"
  tags        = ["tf", "dev"]
  started     = true
  node_name   = "pve"
  vm_id       = 221

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled   = true
  }
  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = false

  cpu {
    cores        = 2
    type         = "host"
    units        = 1024
  }
  memory {
    dedicated    = 2048
    floating     = 0
  } 
  scsi_hardware = "virtio-scsi-single"
  disk {
    datastore_id = "local-lvm" # or your datastore, wherever you store your VM disks
    interface    = "scsi0"
    size         = 32
    path_in_datastore = "vm-221-disk-0"
    file_format       = "raw"
    iothread          = true
  }
  initialization {
    ip_config {
      ipv4 {
        address = "10.10.110.121/23"
        gateway = "10.10.110.1"
      }
    }
    dns {
      servers = [ 
        "10.10.110.2"
        ]
    }
  }

  network_device {
    bridge = "vmbr0"
    mac_address = "BB:CC:DD:EE:FF:11"
  }
  operating_system {
    type = "l26"
  }
  serial_device {}
}

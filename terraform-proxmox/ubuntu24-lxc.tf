# Docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file
# To import an existing LXC template file:
##   terraform import proxmox_virtual_environment_file.ubuntu-24-04-standard_amd64 pve/local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst

resource "proxmox_virtual_environment_file" "ubuntu-24-04-standard_amd64" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve"
  overwrite = false
}

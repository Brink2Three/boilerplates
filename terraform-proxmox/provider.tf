terraform {
  required_version = ">= 1.13.2"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.87.0"
    }
  }
}

variable "proxmox_base_url" {
  type = string  
}
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

provider "proxmox" {
  endpoint  = var.proxmox_base_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  # API Token format: "terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  insecure = true # If using self-signed certs on endpoint URL
}

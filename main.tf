terraform {
  required_version = ">= 0.13"
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.8.2"
    }
  }
}

provider "vcd" {
  user                 = "administrator"
  password            = var.vcd_password
  auth_type           = "integrated"
  org                 = "APT001"
  vdc                 = "apt001-ccm"
  url                 = "https://central1.arkdnacloud.com/api"
  allow_unverified_ssl = true
}

# Create a vApp
resource "vcd_vapp" "vapp" {
  name        = var.vm_name
  description = "GPT-Neo Inference API vApp"
}

# Connect vApp to org network
resource "vcd_vapp_org_network" "vappnet" {
  vapp_name        = vcd_vapp.vapp.name
  org_network_name = "Trust"
}

# Create the VM within the vApp
resource "vcd_vapp_vm" "vm" {
  vapp_name     = vcd_vapp.vapp.name
  name          = var.vm_name
  computer_name = var.vm_name
  
  # Hardware configuration
  memory        = 32768  # 32 GB
  cpus          = 16
  cpu_cores     = 1
  cpu_hot_add_enabled = true
  memory_hot_add_enabled = true

  # OS Template
  catalog_name  = "Local Catalog"
  template_name = "ubuntu-24-04-template"
  
  # Network configuration
  network {
    type               = "org"
    name               = "Trust"
    ip_allocation_mode = "MANUAL"
    ip                = "10.0.0.100"
    adapter_type      = "VMXNET3"
    connected         = true
  }

  # Cloud-init configuration
  guest_properties = {
    "guestinfo.userdata" = base64encode(templatefile("cloud-init.tpl", {
      ssh_public_key = var.ssh_public_key
    }))
    "guestinfo.userdata.encoding" = "base64"
  }
}

# Outputs for easy reference
output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = vcd_vapp_vm.vm.network[0].ip
}

output "vm_name" {
  description = "Name of the deployed VM"
  value       = vcd_vapp_vm.vm.name
}

output "vapp_name" {
  description = "Name of the vApp"
  value       = vcd_vapp.vapp.name
}

output "vm_ip" {
  description = "The IP address assigned to the VM"
  value       = vcd_vapp_vm.vm.network[0].ip
}

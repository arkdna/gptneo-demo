variable "vcd_user" {
  description = "VCD administrator username"
  type        = string
}

variable "vcd_password" {
  description = "VCD administrator password"
  type        = string
  sensitive   = true
}

variable "vcd_org" {
  description = "VCD organization"
  type        = string
}

variable "vcd_vdc" {
  description = "VCD virtual datacenter"
  type        = string
}

variable "vcd_url" {
  description = "VCD API URL"
  type        = string
}

variable "network_segment" {
  description = "Network segment to connect the VM to"
  type        = string
}

variable "template_name" {
  description = "Name of the VM template to use"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM and vApp to be created"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "default_gateway" {
  description = "Default gateway for the VM"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
}

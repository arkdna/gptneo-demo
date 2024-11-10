#!/bin/bash

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and set your variables:"
    echo "cp .env.example .env"
    exit 1
fi

# Load environment variables
source scripts/load_env.sh

# Generate terraform.tfvars
cat > terraform.tfvars << EOF
# Generated from .env - do not edit directly

# VCD Configuration
vcd_user        = "${VCD_USER}"
vcd_password    = "${VCD_PASSWORD}"
vcd_org         = "${VCD_ORG}"
vcd_vdc         = "${VCD_VDC}"
vcd_url         = "${VCD_URL}"

# Network Configuration
network_segment = "${NETWORK_SEGMENT}"
default_gateway = "${DEFAULT_GATEWAY}"
dns_servers     = ${DNS_SERVERS}

# VM Configuration
vm_name         = "${VM_NAME}"
template_name   = "${TEMPLATE_NAME}"

# SSH Configuration
ssh_public_key  = "${SSH_PUBLIC_KEY}"

# Hardware Configuration
vm_memory               = ${VM_MEMORY:-32768}
vm_cpus                 = ${VM_CPUS:-16}
vm_cpu_cores            = ${VM_CPU_CORES:-1}
vm_cpu_hot_add_enabled = ${VM_CPU_HOT_ADD_ENABLED:-true}
vm_memory_hot_add_enabled = ${VM_MEMORY_HOT_ADD_ENABLED:-true}
vm_catalog_name         = "${VM_CATALOG_NAME:-Local Catalog}"
vm_ip                   = "${VM_IP}"
vm_disk_size            = ${VM_DISK_SIZE:-81920}
EOF

# Initialize Terraform
terraform init

# Plan Terraform configuration
terraform plan

# Apply Terraform configuration
terraform apply
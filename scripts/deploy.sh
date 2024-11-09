#!/bin/bash

# Load environment variables
source scripts/load_env.sh

# Initialize Terraform
terraform init

# Apply Terraform configuration
terraform apply \
  -var="vcd_user=${VCD_USER}" \
  -var="vcd_password=${VCD_PASSWORD}" \
  -var="vcd_org=${VCD_ORG}" \
  -var="vcd_vdc=${VCD_VDC}" \
  -var="vcd_url=${VCD_URL}" \
  -var="vm_name=${VM_NAME}" \
  -var="network_segment=${NETWORK_SEGMENT}" \
  -var="template_name=${TEMPLATE_NAME}" \
  -var="default_gateway=${DEFAULT_GATEWAY}" \
  -var="dns_servers=${DNS_SERVERS}" \
  -var="ssh_public_key=${SSH_PUBLIC_KEY}"
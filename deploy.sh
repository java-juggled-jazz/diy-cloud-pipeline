#!/bin/bash

# Declaring SSH Keys Dir Variables
CENTRAL_HOST_SSH_KEY_DIR="~/.ssh/diy-cloud-pipeline-keys/"
BUILDER_HOST_SSH_KEY_DIR="~/.ssh/diy-cloud-pipeline-keys/"

# Exporting Secrets
export .env_vars

# Creating Central Host SSH Key
mkdir -p $CENTRAL_HOST_SSH_KEY_DIR
ssh-keygen -t rsa -b 2048 -f $CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central" -N "$CENTRAL_HOST_PASSPHRASE"

# Creating Builder Host SSH Key
mkdir -p $BUILDER_HOST_SSH_KEY_DIR
ssh-keygen -t rsa -b 2048 -f $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder" -N "$BUIDER_HOST_PASSPHRASE"

# Creating Cloud Resources
cd terraform
terraform init
terraform apply -auto-approve -var central_vm_ssh_key_dir=$BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub"
cd ..

# Exporting Terraform Outputs To Secrets
terraform output -json | jq -r 'to_entries[] | .key + "=" + "\"" + (.value.value | tostring) + "\""' | while read -r line ; do echo export "$line"; done > env.sh && source env.sh && rm env.sh

# Creating Temporary Builder VM
yc compute instance create \
  --name builder-vm \
  --zone $TF_VAR_availability-zone \
  --create-boot-disk image-id=$BUILDER_VM_IMAGE_ID,size=$BUILDER_VM_DISK_SIZE,type=network-ssd \
  --memory $BUILDER_VM_MEMORY --cores $BUILDER_VM_CORES --core-fraction $BUILDER_VM_CORE_FRACTION \
  --network-interface subnet-id=$SUBNET_ID \
  --ssh-key $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
  --format=yaml --no-user-output > ./outputs/builder-vm-output.yaml

# Processing YAML-file to extract Builder VM ID, its Internal IP and its Boot Disk ID into a spectific file
yq '("builder_vm_id: " + .id),("builder_vm_internal_ip: " + .network_interfaces[0].primary_v4_address.address),("builder_vm_internal_ip: " + .network_interfaces[0].primary_v4_address.address),("boot_disk_id: " + .boot_disk.disk_id)' builder-vm-output.yaml -r > ./ansible/vars/builder_vm_vars.yaml

# Exporting Builder VM ID, Internal IP and Boot Disk ID
export BUILDER_VM_ID=$(yq -r '.id' ./ansible/vars/builder_vm_vars.yaml)
export BUILDER_VM_INTERNAL_IP=$(yq -r '.builder_vm_internal_ip' ./ansible/vars/builder_vm_vars.yaml)
export BUILDER_VM_BOOT_DISK_ID=$(yq -r '.boot_disk_id' ./ansible/vars/builder_vm_vars.yaml)

# Setting IP-Addresses into Ansible Inventory file
yq '.central.hosts."host-one" = "'$CENTRAL_HOST_IP'" | .builder.hosts."host-one" = "'$BUILDER_VM_INTERNAL_IP'"' ./ansible/inventory.yaml -y > ./ansible/inventory.yaml

# Starting Playbook For Configuring Builder VM
ansible-playbook builder-vm-configure.yaml -i inventory.yaml

# Creating Temporary Builder VM Snapshot
yc compute snapshot create \
  --name builder-snapshot \
  --disk-id $BUILDER_BOOT_DISK_ID \
  --labels $PROJECT_NAME_KEY=$PROJECT_NAME_VALUE \
  --format=yaml --no-user-output > ./outputs/builder-vm-snapshot-output.yaml

# Destroying Temporary Builder VM
yc compute instance delete \
  --id $BUILDER_VM_ID \
  --async --no-user-output

# Starting Playbook For Configuring Central VM
ansible-playbook central-vm-configure.yaml -i inventory.yaml

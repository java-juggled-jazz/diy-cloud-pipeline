#!/bin/bash

# Declaring SSH Keys Dir Variables
CENTRAL_HOST_SSH_KEY_DIR=$HOME"/.ssh/diy-cloud-pipeline-keys/"
BUILDER_HOST_SSH_KEY_DIR=$HOME"/.ssh/diy-cloud-pipeline-keys/"

# Exporting Secrets
source .env_vars

# Creating Central Host SSH Key
mkdir -p $CENTRAL_HOST_SSH_KEY_DIR
rm $CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central" $CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central.pub"
ssh-keygen -t rsa -b 2048 -f $CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central" -N "$CENTRAL_HOST_PASSPHRASE"

# Creating Builder Host SSH Key
mkdir -p $BUILDER_HOST_SSH_KEY_DIR
rm $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder" $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub"
ssh-keygen -t rsa -b 2048 -f $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder" -N "$BUIDER_HOST_PASSPHRASE"

# Creating Cloud Resources
cd terraform
terraform init
terraform apply -auto-approve -var central_vm_ssh_key_dir=$BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
  -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
  -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
  -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
  -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
  -var central_vm_ssh_key_dir=$CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central.pub" -var service_account_id=$TF_VAR_service_account_id \
  -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)

# Exporting Terraform Outputs To Secrets
terraform output -json | jq -r 'to_entries[] | .key + "=" + "\"" + (.value.value | tostring) + "\""' | while read -r line ; do echo export "$line"; done > env.sh && source env.sh && rm env.sh

cd ..
mkdir -p ./outputs/

# Creating Temporary Builder VM
yc compute instance create \
  --name builder-vm \
  --zone $TF_VAR_availability_zone \
  --create-boot-disk image-id=$BUILDER_VM_IMAGE_ID,size=$BUILDER_VM_DISK_SIZE,type=network-ssd \
  --memory $BUILDER_VM_MEMORY --cores $BUILDER_VM_CORES --core-fraction $BUILDER_VM_CORE_FRACTION \
  --network-interface subnet-id=$SUBNET_ID,nat-ip-version=ipv4 \
  --ssh-key $BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
  --format=yaml --no-user-output > ./outputs/builder-vm-output.yaml

mkdir -p ./ansible/vars/

# Processing YAML-file to extract Builder VM ID, its Internal IP and its Boot Disk ID into a spectific file
yq '("builder_vm_id: " + .id),("builder_vm_ip: " + .network_interfaces[0].primary_v4_address.one_to_one_nat.address),("builder_vm_internal_ip: " + .network_interfaces[0].primary_v4_address.address),("boot_disk_id: " + .boot_disk.disk_id)' ./outputs/builder-vm-output.yaml -r > ./ansible/vars/builder-vm-vars.yaml

# Exporting Builder VM ID, Internal IP and Boot Disk ID
export BUILDER_VM_ID=$(yq -r '.id' ./ansible/vars/builder-vm-vars.yaml)
export BUILDER_VM_INTERNAL_IP=$(yq -r '.builder_vm_ip' ./ansible/vars/builder-vm-vars.yaml)
export BUILDER_VM_BOOT_DISK_ID=$(yq -r '.boot_disk_id' ./ansible/vars/builder-vm-vars.yaml)

# Setting IP-Addresses into Ansible Inventory file
yq '.central.hosts."host-one".ansible_host = "'$CENTRAL_HOST_IP'" | .central.users.service_user = "'$ANSIBLE_CENTRAL_VM_SERVICE_USER'" | .builder.hosts."host-one".ansible_host = "'$BUILDER_VM_INTERNAL_IP' | .builder.users.service_user = "'$ANSIBLE_BUILDER_VM_SERVICE_USER'""' ./ansible/inventory_template.yaml -y > ./ansible/inventory.yaml

# Starting Playbook For Configuring Builder VM
ansible-playbook ./ansible/builder-vm-configure.yaml -i ./ansible/inventory.yaml

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
ansible-playbook ./ansible/central-vm-configure.yaml -i ./ansible/inventory.yaml

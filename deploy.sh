!#/bin/sh

# Exporting Secrets
source .env_vars

# Creating SSH Keys
mkdir -p ~/.ssh/diy-cloud-pipeline-keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/diy-cloud-pipeline-keys/id_rsa -N "$PASSPHRASE"

# Creating Cloud Resources
cd terraform
terraform init
terraform apply -auto-approve
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
  --format=yaml --no-user-output > ./outputs/builder-vm-output.yaml

# Processing YAML-file to extract Builder VM ID, its Internal IP and its Boot Disk ID into a spectific file
yq '("builder_vm_id: " + .id),("builder_vm_internal_ip: " + .network_interfaces[0].primary_v4_address.address),("boot_disk_id: " + .boot_disk.disk_id)' builder-vm-output.yaml -r > ./ansible/vars/builder_vm_vars.yaml

# Exporting Builder VM
export BUILDER_VM_ID=$(yq -r '.id' ./ansible/vars/builder_vm_vars.yaml)

# Starting Playbook For Configuring Builder VM
ansible-playbook builder-vm-configure.yaml -i inventory.yaml

# Creating Temporary Builder VM Snapshot
yc compute snapshot create \
  --name builder-snapshot \
  --disk-id $BUILDER_DISK_ID \
  --labels $PROJECT_NAME_KEY=$PROJECT_NAME_VALUE \
  --format=yaml --no-user-output > ./outputs/builder-vm-snapshot-output.yaml

# Destroying Temporary Builder VM
yc compute instance delete \
  --id $BUILDER_VM_ID \
  --async --no-user-output

# Starting Playbook For Configuring Central VM
ansible-playbook central-vm-configure.yaml -i inventory.yaml

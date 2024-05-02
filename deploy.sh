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
  --format=yaml --no-user-output > ./outputs/vm-output.yaml

yq '("BUILDER_VM_ID=" + .id),("BUILDER_VM_INTERNAL_IP=" + .network_interfaces[0].primary_v4_address.address)' vm-output.yaml -r

# ANSIBLE
# IS
# HERE

# Creating Temporary Builder VM Snapshot
yc compute snapshot create \
  --name builder-snapshot \
  --disk-id $BUILDER_DISK_ID \
  --labels $PROJECT_NAME_KEY=$PROJECT_NAME_VALUE \
  --async

# Destroy Temporary Builder VM
yc compute instance destroy \
  --id $BUILDER_VM_ID \
  --async

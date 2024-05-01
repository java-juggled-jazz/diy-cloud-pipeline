!#/bin/sh

# Exporting Secrets
source .secrets

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
  --name builder \
  --zone $AVAILABILITY_ZONE \
  --create-boot-disk image-id=$BUILDER_IMAGE_ID,size=30,type=network-ssd \
  --image-folder-id standard-images \
  --memory $MEMORY --cores $CORES --core-fraction $CORE_FRACTION \
  --network-interface subnet-id=$SUBNET_ID,nat-ip-version=ipv4 \
  --async 

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

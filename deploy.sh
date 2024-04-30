!#/bin/sh

source .secrets

mkdir -p ~/.ssh/diy-cloud-pipeline-keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/diy-cloud-pipeline-keys/id_rsa -N "$PASSPHRASE"

cd terraform
terraform init
terraform apply -auto-approve
cd ..

# HERE
# IT CREATES
# TEMPORARY BUILDER VM

# ANSIBLE
# IS
# HERE

# HERE
# IT CREATES
# BUILDER VM'S DISK SNAPSHOT
# AND DESTROYS IT

!#/bin/sh

# HERE
# IT GENERATES
# SSH KEYS FOR VMS

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

#!/bin/bash

# Checking The Flag
case $1 in
# Display Help Page
    "help" | "h")
      cat README.md
      exit
    ;;

    "" | "deploy" | "test")
      ;;

# Unrecognized Option
    *)
      echo -e "Unrecognized option \"$1\"\nType \"deploy.sh help\" for a list of available options."
      exit
    ;;
esac

# Declaring SSH Keys Dir Variable
SSH_KEY_DIR=$HOME"/.ssh/diy-cloud-pipeline-keys/"

# Exporting Secrets
source .env_vars

# Creating Central Host SSH Key
mkdir -p $SSH_KEY_DIR
rm $SSH_KEY_DIR"id_rsa_central" $SSH_KEY_DIR"id_rsa_central.pub"
ssh-keygen -t rsa -b 2048 -f $SSH_KEY_DIR"id_rsa_central" -N "$CENTRAL_HOST_PASSPHRASE" -C ""

# Creating Builder Host SSH Key
mkdir -p $SSH_KEY_DIR
rm $SSH_KEY_DIR"id_rsa_builder" $SSH_KEY_DIR"id_rsa_builder.pub"
ssh-keygen -t rsa -b 2048 -f $SSH_KEY_DIR"id_rsa_builder" -N "$BUIDER_HOST_PASSPHRASE" -C ""

# Creating Cloud Resources

mkdir -p ./cloud-init/

#echo "#cloud-init" > ./cloud-init/central-vm.yaml && yq -ny '.datasource.Ec2.strict_id = false | .users = [] | .users[0].name = "'$ANSIBLE_CENTRAL_VM_SERVICE_USER'" | .users[0].sudo = "ALL=(ALL) NOPASSWD:ALL" | .users[0].shell = "/bin/bash" | .users[0].ssh_authorized_keys = [] | .users[0].ssh_authorized_keys[0] = "'"$(echo $(cat $SSH_KEY_DIR"id_rsa_central.pub"))"'"' >> ./cloud-init/central-vm.yaml && echo "#cloud-config" >> ./cloud-init/central-vm.yaml && yq -ny '.runcmd = []' >> ./cloud-init/central-vm.yaml

# Checking The Flag Again And Executing The Command Depending On Value
case $1 in
# Deploy with K8s
  "" | "deploy")
    echo Deploy...
    cd terraform
    terraform init
    terraform apply -auto-approve \
      -var ssh_keys="$ANSIBLE_BUILDER_VM_SERVICE_USER:$(echo $(cat $SSH_KEY_DIR'id_rsa_builder.pub'))" \
      -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
      -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
      -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
      -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
      -var central_vm_userdata="../cloud-init/central-vm.yaml" -var service_account_id=$TF_VAR_service_account_id \
      -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)
    ;;

# Deploy without K8s. Tests Only. Don't Forget To Add Target Files After Adding Config Files
  "test")
    echo Test...
    mkdir -p terraform-test
    cd terraform-test
    for file_name in $(cd ../terraform && ls | grep -e ".tf$" | grep -v "k8s"); do cp ../terraform/$file_name $file_name; done;
    terraform init
    terraform apply -auto-approve \
      -var ssh_keys="$ANSIBLE_BUILDER_VM_SERVICE_USER:$(echo $(cat $SSH_KEY_DIR'id_rsa_builder.pub'))" \
      -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
      -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
      -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
      -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
      -var central_vm_userdata="../cloud-init/central-vm.yaml" -var service_account_id=$TF_VAR_service_account_id \
      -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)
    ;;
esac

# Exporting Terraform Outputs To Secrets
terraform output -json | jq -r 'to_entries[] | .key + "=" + "\"" + (.value.value | tostring) + "\""' | while read -r line ; do echo export "$line"; done > env.sh && source env.sh

cd ..

mkdir -p ./outputs/

echo "Creating Builder VM..."

#echo "#cloud-config" > ./cloud-init/builder-vm.yaml && yq -ny '.datasource.Ec2.strict_id = false | .ssh_pwauth = "no" | .users = [] | .users[0].name = "'$ANSIBLE_BUILDER_VM_SERVICE_USER'" | .users[0].sudo = "ALL=(ALL) NOPASSWD:ALL" | .users[0].shell = "/bin/bash" | .users[0].ssh_authorized_keys = [] | .users[0].ssh_authorized_keys[0] = "'"$(echo $(cat $SSH_KEY_DIR"id_rsa_builder.pub"))"'"' >> ./cloud-init/builder-vm.yaml && echo "#cloud-config" >> ./cloud-init/builder-vm.yaml && yq -ny '.runcmd = []' >> ./cloud-init/builder-vm.yaml

# Creating Temporary Builder VM
yc compute instance create \
  --name builder-vm \
  --zone $TF_VAR_availability_zone \
  --create-boot-disk image-id=$BUILDER_VM_IMAGE_ID,size=$BUILDER_VM_DISK_SIZE,type=network-ssd \
  --memory $BUILDER_VM_MEMORY --cores $BUILDER_VM_CORES --core-fraction $BUILDER_VM_CORE_FRACTION \
  --network-interface subnet-id=$SUBNET_ID,nat-ip-version=ipv4 \
  --ssh-key $SSH_KEY_DIR'id_rsa_builder.pub' \
  --format=yaml --no-user-output > ./outputs/builder-vm-output.yaml

echo "Created Builder VM."

mkdir -p ./ansible/vars/

# Processing YAML-file to extract Builder VM ID, its Internal IP and its Boot Disk ID into a spectific file
yq '("builder_vm_id: " + .id),("builder_vm_ip: " + .network_interfaces[0].primary_v4_address.one_to_one_nat.address),("builder_vm_internal_ip: " + .network_interfaces[0].primary_v4_address.address),("boot_disk_id: " + .boot_disk.disk_id)' ./outputs/builder-vm-output.yaml -r > ./ansible/vars/builder-vm-vars.yaml

# Exporting Builder VM ID, Internal IP and Boot Disk ID
export BUILDER_VM_ID=$(yq -r '.id' ./ansible/vars/builder-vm-vars.yaml)
export BUILDER_VM_INTERNAL_IP=$(yq -r '.builder_vm_ip' ./ansible/vars/builder-vm-vars.yaml)
export BUILDER_VM_BOOT_DISK_ID=$(yq -r '.boot_disk_id' ./ansible/vars/builder-vm-vars.yaml)

# Setting IP-Addresses into Ansible Inventory file
yq '.central.hosts."host-one".ansible_host = "'$CENTRAL_HOST_IP'" | .central.hosts."host-one".service_user = "yc-user" | .central.hosts."host-one".ansible_ssh_private_key_file = "'$SSH_KEY_DIR"id_rsa_central"'" |  .builder.hosts."host-one".ansible_host = "'$BUILDER_VM_INTERNAL_IP'" | .builder.hosts."host-one".service_user = "yc-user" | .builder.hosts."host-one".ansible_ssh_private_key_file = "'$SSH_KEY_DIR"id_rsa_builder"'"' ./ansible/inventory_template.yaml -y > ./ansible/inventory.yaml

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

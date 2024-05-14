#!/bin/bash

# Declaring SSH Keys Dir Variables
CENTRAL_HOST_SSH_KEY_DIR=$HOME"/.ssh/diy-cloud-pipeline-keys/"

# Exporting Secrets
source .env_vars

# Checking The Flag And executing The Command Depending On Value
case $1 in
# Destroy Instances With K8s
  "" )
    cd terraform
    terraform init
    terraform destroy -auto-approve -var central_vm_ssh_key_dir=$BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
      -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
      -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
      -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
      -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
      -var central_vm_ssh_key_dir=$CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central.pub" -var service_account_id=$TF_VAR_service_account_id \
      -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)
    ;;

## Destroy Test-Instances (Deployed without K8s)
  "test" )
    cd terraform-test
    terraform init
    terraform destroy -auto-approve -var central_vm_ssh_key_dir=$BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
      -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
      -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
      -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
      -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
      -var central_vm_ssh_key_dir=$CENTRAL_HOST_SSH_KEY_DIR"id_rsa_central.pub" -var service_account_id=$TF_VAR_service_account_id \
      -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)
    ;;
esac
cd ..

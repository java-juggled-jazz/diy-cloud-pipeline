#!/bin/bash

# Exporting Secrets
source .env_vars

# Destroy Instances
cd terraform
terraform init
terraform destroy -auto-approve -var central_vm_ssh_key_dir=$BUILDER_HOST_SSH_KEY_DIR"id_rsa_builder.pub" \
  -var cloud_id=$TF_VAR_cloud_id -var folder_id=$TF_VAR_folder_id \
  -var availability_zone=$TF_VAR_availability_zone -var central_vm_cores=$TF_VAR_central_vm_cores \
  -var central_vm_core_fraction=$TF_VAR_central_vm_core_fraction -var central_vm_memory=$TF_VAR_central_vm_memory \
  -var central_vm_image_id=$TF_VAR_central_vm_image_id -var central_vm_disk_size=$TF_VAR_central_vm_disk_size \
  -var service_account_id=$TF_VAR_service_account_id \
  -var project_label=$TF_VAR_project_label -var yandex_iam_token=$(yc iam create-token)
cd ..

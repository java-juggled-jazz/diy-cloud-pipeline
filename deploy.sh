!#/bin/sh

cd terraform
terraform init
terraform apply -auto-approve
cd ..

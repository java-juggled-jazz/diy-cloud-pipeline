terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.availability_zone
  token = var.yandex_iam_token
}

resource "yandex_vpc_network" "cloud-pipeline-net" {
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "cloud-pipeline-subnet" {
  zone           = var.availability_zone
  folder_id = var.folder_id
  network_id     = yandex_vpc_network.cloud-pipeline-net.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

output "SUBNET_ID" {
  value     = yandex_vpc_subnet.cloud-pipeline-subnet.id
  sensitive = false
}

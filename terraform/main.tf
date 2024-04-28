variable "availability_zone" {
  type = string
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.availablity_zone
}

resource "yandex_vpc_network" "cloud-pipeline-net" {}

resource "yandex_vpc_subnet" "cloud-pipeline-subnet" {
  zone           = var.availability_zone
  network_id     = yandex_vpc_network.cloud-pipeline-net.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

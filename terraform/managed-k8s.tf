resource "yandex_kubernetes_cluster" "managed-k8s" {
  name        = "managed-k8s"

  network_id = yandex_vpc_network.cloud-pipeline-net.id

  master {
    version = "1.17"
    zonal {
      zone = var.availability-zone
      subnet_id = yandex_vpc_network.cloud-pipeline-net.id
    }

    public_ip = false

//    security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]
  }

  service_account_id = var.service-account-id
  node_service_account_id = var.service-account-id

  labels = {
    my_key       = "my_value"
    my_other_key = "my_other_value"
  }

  release_channel = "RAPID"
}

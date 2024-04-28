resource "yandex_kubernetes_cluster" "managed-k8s" {
  name        = "managed-k8s"

  network_id = yandex_vpc_network.cloud-pipeline-net.id

  master {
    version = "1.17"
    zonal {
      zone = var.availability-zone
      subnet_id = yandex_vpc_subnet.cloud-pipeline-subnet.id
    }

    public_ip = false

    security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
  }

  service_account_id = var.service-account-id
  node_service_account_id = var.service-account-id

  labels = {
    project_label = var.project_label
  }

  release_channel = "STABLE"
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id

  ingress {
    protocol          = "TCP"
    description       = "The rule is allowing heathchecks from load balancer addresses range. It is needed for fault-tolerant-cluster working and load balancer services"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "The rule is allowing master-node and node-node interaction inside security group"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "The rule is allowing pod-pod and service-service interaction"
    v4_cidr_blocks    = concat(yandex_vpc_subnet.cloud-pipeline-subnet.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ICMP"
    description       = "Service ICMP-packets from internal subnets are allowed"
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }

  egress {
    protocol          = "ANY"
    description       = "All egress traffic is allowed"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

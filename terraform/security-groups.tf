resource "yandex_vpc_security_group" "vm-security-group" {
  name        = "VM Security Group"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
  }
  
  egress {
    protocol       = "ANY"
    description    = "Outgoing packets"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s-lb-security-group" {
  name        = "Kubernetes Load Balancer Security Group"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
  }
  
  egress {
    protocol       = "ANY"
    description    = "Outgoing packets"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

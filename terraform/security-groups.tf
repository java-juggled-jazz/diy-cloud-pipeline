resource "yandex_vpc_security_group" "vm-security-group" {
  name        = "vm-security-group"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["10.1.0.0/24"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["10.1.0.0/24"]
    port           = 80
  }
  
  egress {
    protocol       = "ANY"
    description    = "Outgoing packets"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s-lb-security-group" {
  name        = "kubernetes-load-balancer-security-group"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["10.1.0.0/24"]
    port           = 80
  }
  
  egress {
    protocol       = "ANY"
    description    = "Outgoing packets"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

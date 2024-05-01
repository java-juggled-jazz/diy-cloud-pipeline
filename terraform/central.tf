resource "yandex_compute_disk" "boot-disk-central" {
  name     = "central-host-boot-disk"
  type     = "network-ssd"
  zone     = var.availability-zone
  size     = var.central-host-vars.disk_size
  image_id = var.central-host-vars.image_id
}

resource "yandex_compute_instance" "central-host" {
  name        = "central-host"
  platform_id = "standard-v1"
  zone        = var.availability-zone

  resources {
    cores  = var.central-host-vars.cores
    core_fraction = var.central-host-vars.core_fraction
    memory = var.central-host-vars.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-central.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.cloud-pipeline-subnet.id
    security_group_ids = [yandex_vpc_security_group.vm-security-group.id]
    nat = true
  }

  metadata = {
    ssh-keys = ""
  }

  labels = {
    project_label = var.project_label
  }
}

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

  labels = {
    project_label = var.project_label
  }
}

output "CENTRAL_HOST_IP" {
  value     = yandex_compute_instance.central-host.network_interface.0.nat_ip_address
  sensitive = false
}

resource "yandex_compute_disk" "boot-disk-central" {
  name     = "central-host-boot-disk"
  folder_id = var.folder_id
  type     = "network-ssd"
  zone     = var.availability_zone
  size     = tonumber("${var.central_vm_disk_size}")
  image_id = var.central_vm_image_id
}

resource "yandex_compute_instance" "central-host" {
  name        = "central-host"
  platform_id = "standard-v1"
  zone        = var.availability_zone
  folder_id = var.folder_id

  resources {
    cores  = var.central_vm_cores
    core_fraction = var.central_vm_core_fraction
    memory = var.central_vm_memory
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
    ssh-keys = "${file(var.central_vm_ssh_key_dir)}"
  }

  labels = {
    project_label = var.project_label
  }
}

resource "yandex_vpc_security_group" "vm-security-group" {
  name        = "vm-security-group"
  network_id  = yandex_vpc_network.cloud-pipeline-net.id
  folder_id = var.folder_id

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
    project-label = var.project_label
  }
}

output "CENTRAL_HOST_IP" {
  value     = yandex_compute_instance.central-host.network_interface.0.nat_ip_address
  sensitive = false
}

output "CENTRAL_HOST_INTERNAL_IP" {
  value     = yandex_compute_instance.central-host.network_interface.0.ip_address
  sensitive = false
}

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
    nat = true
  }

  metadata = {
    ssh-keys = ""
  }

  labels = {
    project_label = var.project_label
  }
}

output "central-host-ip" {
  value     = yandex_compute_instance.central-host.network_interface.0.nat_ip_address
  sensitive = false
}

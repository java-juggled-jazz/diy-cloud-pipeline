variable "jenkins-host-vars" {
  type = object({
    cores = number
    core_fraction = number
    memory = number
  })
}

resource "yandex_compute_instance" "jenkins-host" {
  name        = "jenkins-host"
  platform_id = "standard-v1"
  zone        = var.availability_zone

  resources {
    cores  = var.jenkins-host-vars.cores
    core_fraction = var.jenkins-host-vars.core_fraction
    memory = var.jenkins-host-vars.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.cloud-pipeline-subnet.id}"
  }

  metadata = {
    ssh-keys = ""
  }
}

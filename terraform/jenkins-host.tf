resource "yandex_compute_instance" "jenkins-host" {
  name        = "jenkins-host"
  platform_id = "standard-v1"
  zone        = var.availablity_zone

  resources {
    cores  = var.jenkins-host.cores
    core_fraction = var.jenkins-host.cores
    memory = var.jenkins-host.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.foo.id}"
  }

  metadata = {
    ssh-keys = ""
  }
}

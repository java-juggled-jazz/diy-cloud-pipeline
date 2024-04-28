resource "yandex_lb_network_load_balancer" "load-balancer" {
  name = "load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  labels = {
    project_label = var.project_label
  }
}

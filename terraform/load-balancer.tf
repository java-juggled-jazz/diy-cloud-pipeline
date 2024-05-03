resource "yandex_lb_network_load_balancer" "pipeline-load-balancer" {
  name = "load-balancer"
  folder_id = var.folder_id

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  labels = {
    project-label = var.project_label
  }
}

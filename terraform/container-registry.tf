resource "yandex_container_registry" "registry" {
  name = "Container Registry"
  folder_id = var.folder_id
  labels = {
    project_label = "cloud-pipeline"
  }
}

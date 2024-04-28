resource "yandex_container_registry" "registry" {
  name = "Container Registry"
  folder_id = var.folder-id
  labels = {
    project_label = "cloud-pipeline"
  }
}

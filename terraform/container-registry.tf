resource "yandex_container_registry" "registry" {
  name = "container-registry"
  folder_id = var.folder-id
  labels = {
    project_label = "cloud-pipeline"
  }
}

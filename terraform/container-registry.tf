resource "yandex_container_registry" "pipeline-registry" {
  name = "container-registry"
  folder_id = var.folder_id
  labels = {
    project-label = var.project_label
  }
}

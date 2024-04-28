resource "yandex_storage_bucket" "pipeline-bucket" {
  max_size = var.pipeline-bucket.max_size
  default_storage_class = var.pipeline-bucket.default_storage_class
  anonymous_access_flags {
    read = false
    list = false
    config_read = false
  }
  access_key = var.sa-static-key.access_key
  secret_key = var.sa-static-key.secret_key
}

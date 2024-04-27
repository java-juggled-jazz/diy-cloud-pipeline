variable "pipeline-bucket" {
  type = object({
    max_size = number
    default_storage_class = string
  })
}

resource "yandex_storage_bucket" "pipeline-bucket" {
  max_size = var.pipeline-bucket.max_size
  default_storage_class = var.pipeline-bucket.default_storage_class
  anonymous_access_flags {
    read = false
    list = false
    config_read = false
  }
}

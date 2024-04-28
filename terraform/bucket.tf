resource "yandex_iam_service_account_static_access_key" "bucket-sa-static-key" {
  service_account_id = var.service-account-id
  description        = "Static Key For Pipeline Bucket"
}

resource "yandex_storage_bucket" "pipeline-bucket" {
  max_size = var.pipeline-bucket.max_size
  default_storage_class = var.pipeline-bucket.default_storage_class
  anonymous_access_flags {
    read = false
    list = false
    config_read = false
  }
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
}

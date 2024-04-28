variable "cloud-id" {
  type = string
}

variable "folder-id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "central-host-vars" {
  type = object({
    cores = number
    core_fraction = number
    memory = number
    image_id = string
  })
}

variable "pipeline-bucket" {
  type = object({
    max_size = number
    default_storage_class = string
  })
}

variable "service-account" {
  type = string
}

variable "node-service-account" {
  type = string
}

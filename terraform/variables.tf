variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "central_host_vars" {
  type = object({
    cores = number
    core_fraction = number
    memory = number
    image_id = string
    disk_size = number
  })
}

variable "service_account_id" {
  type = string
}

variable "project_label" {
  type = string
}

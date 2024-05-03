variable "cloud-id" {
  type = string
}

variable "folder-id" {
  type = string
}

variable "availability-zone" {
  type = string
}

variable "central-host-vars" {
  type = object({
    cores = number
    core_fraction = number
    memory = number
    image_id = string
    disk_size = number
  })
}

variable "service-account-id" {
  type = string
}

variable "project_label" {
  type = string
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "ssh_keys" {
  type = string
}

variable "central_vm_cores" {
  type = string
}

variable "central_vm_core_fraction" {
  type = string
}

variable "central_vm_memory" {
  type = string
}

variable "central_vm_image_id" {
  type = string
}

variable "central_vm_disk_size" {
  type = string
}

variable "central_vm_userdata" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "project_label" {
  type = string
}

variable "yandex_iam_token" {
  type = string
  sensitive = true
}

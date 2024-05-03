variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "central_vm_cores" {
  type = number
}

variable "central_vm_core_fraction" {
  type = number
}

variable "central_vm_memory" {
  type = number
}

variable "central_vm_image_id" {
  type = string
}

variable "central_vm_disk_size" {
  type = number
}

variable "central_vm_ssh_key_dir" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "project_label" {
  type = string
}

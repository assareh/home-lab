# Read the documentation for locals blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  esxi_password   = vault("/packer/data/esxi", "esxi_password")
  esxi_username   = vault("/packer/data/esxi", "esxi_username")
  ssh_password    = vault("/packer/data/ubuntu", "k3s")
  timestamp       = regex_replace(timestamp(), "[- TZ:]", "")
  vm_name         = "K3s-${local.timestamp}"
}

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.

# Read the documentation for variable blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/variable
variable "esxi_host" {
  type    = string
  default = "esxi.local"
}

variable "network_name" {
  type    = string
  default = "VM Network"
}

variable "remote_datastore" {
  type    = string
  default = "datastore1"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "vm_cpu_num" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "40960"
}

variable "vm_mem_size" {
  type    = string
  default = "8192"
}
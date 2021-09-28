# Read the documentation for locals blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/locals
locals {
  consul_gossip   = vault("/packer/data/consul", "gossip")
  consul_license  = vault("/packer/data/consul", "license")
  esxi_password   = vault("/packer/data/esxi", "esxi_password")
  esxi_username   = vault("/packer/data/esxi", "esxi_username")
  nomad_gossip    = vault("/packer/data/nomad", "gossip")
  nomad_license   = vault("/packer/data/nomad", "license")
  ssh_password    = vault("/packer/data/ubuntu", "castle")
  timestamp       = regex_replace(timestamp(), "[- TZ:]", "")
  vault_license   = vault("/packer/data/vault", "license")
  vm_name         = "Castle-${local.timestamp}"
}

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.

# Read the documentation for variable blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/variable
variable "cni_version" {
  type    = string
  default = "1.0.1"
}

variable "consul_version" {
  type    = string
  default = "1.10.2+ent"
}

variable "containerd_version" {
  type    = string
  default = "0.9.2"
}

variable "esxi_host" {
  type    = string
  default = "esxi.local"
}

variable "network_name" {
  type    = string
  default = "VM Network"
}

variable "nomad_version" {
  type    = string
  default = "1.1.5+ent"
}

variable "remote_datastore" {
  type    = string
  default = "datastore1"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "vault_version" {
  type    = string
  default = "1.8.2+ent"
}

variable "vm_cpu_num" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "163840"
}

variable "vm_mem_size" {
  type    = string
  default = "12288"
}
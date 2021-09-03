variable "esxi_hostname" {
  description = "The address of your ESXi host"
  type        = string
}

variable "esxi_password" {
  description = "ESXi account password to use"
  sensitive   = true
  type        = string
}

variable "esxi_username" {
  description = "ESXi user account name"
  type        = string
}

variable "nodes_blue" {
  description = "A map of host names and MAC addresses for blue nodes"
  type        = map(any)
}

variable "nodes_green" {
  description = "A map of host names and MAC addresses for green nodes"
  type        = map(any)
}

variable "node_moat" {
  description = "A map of host name and network names and MAC addresses for moat node"
  type        = object({ name = string, network_interfaces = map(any) })
}

variable "node_nas" {
  description = "A map of host name and MAC address for nas node"
  type        = object({ name = string, mac_address = string })
}

variable "ssh_private_key" {
  description = "SSH private key to use for provisioner connection to remote hosts"
  type        = string
}

variable "ssh_username" {
  description = "SSH username to use for provisioner connection to remote hosts"
  type        = string
  default     = "ubuntu"
}

variable "template_blue" {
  description = "Name of template to use for blue nodes"
  type        = string
}

variable "template_green" {
  description = "Name of template to use for green nodes"
  type        = string
}

variable "template_moat" {
  description = "Name of template to use for moat nodes"
  type        = string
}

variable "template_nas" {
  description = "Name of template to use for nas nodes"
  type        = string
}

locals {
  blue_hostnames  = [for k, v in var.nodes_blue : k]
  green_hostnames = [for k, v in var.nodes_green : k]
}

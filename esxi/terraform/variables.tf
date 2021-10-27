variable "esxi_datastore" {
  description = "The ESXi datastore where the virtual machines will be created"
  type        = string
}

variable "esxi_datastore_nas_mirror" {
  description = "The ESXi datastore where the NAS mirror disk will be created"
  type        = string
}

variable "esxi_hostname" {
  description = "The address of your ESXi host"
  type        = string
}

variable "esxi_network_name" {
  description = "The ESXi network name to attach the network interfaces"
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

variable "nas_allow_ip_cidr" {
  description = "This value will be used in the NAS /etc/exports file to specify which IP CIDR is allowed to access the NFS share. Example: 192.168.0.0/24"
  type        = string
}

variable "nas_disk_size" {
  description = "Size (in GB) of storage volume to create on NAS VM"
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

variable "node_k3s" {
  description = "A map of host name and MAC address for k3s node"
  type        = object({ name = string, mac_address = string })
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

variable "template_k3s" {
  description = "Name of template to use for k3s nodes"
  type        = string
}

variable "template_nas" {
  description = "Name of template to use for nas node"
  type        = string
}

locals {
  blue_hostnames  = [for k, v in var.nodes_blue : k]
  green_hostnames = [for k, v in var.nodes_green : k]
}

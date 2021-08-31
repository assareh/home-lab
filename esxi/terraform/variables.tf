variable "esxi_hostname" {
  description = "The address of your ESXi host"
}

variable "esxi_password" {
  description = "ESXi account password to use"
}

variable "esxi_username" {
  description = "ESXi user account name"
}

variable "nodes_blue" {
  description = "A map of host name and MAC address for blue nodes (if you are using Terraform Cloud set variable type to HCL)"
}

variable "nodes_green" {
  description = "A map of host name and MAC address for green nodes (if you are using Terraform Cloud set variable type to HCL)"
}

variable "nodes_moat" {
  description = "A map of host name and MAC address for moat nodes (if you are using Terraform Cloud set variable type to HCL)"
  default     = {}
}

variable "secret_id" {
  description = "Secret ID to provide node for its bootstrap script"
}

variable "ssh_private_key" {
  description = "SSH private key to use for provisioner connection to remote hosts"
}

variable "temp" {
  description = "unused variable. using as a pasteboard"
}

variable "template_blue" {
  description = "Name of template to use for blue nodes"
}

variable "template_green" {
  description = "Name of template to use for green nodes"
}

variable "template_moat" {
  description = "Name of template to use for moat nodes"
}
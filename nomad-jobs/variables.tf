variable "dns_servers" {
  description = "List of DNS servers (per https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job#variables value must be provided as string, no escaping necessary"
  type        = string
}

variable "domain" {
  description = "Domain"
  type        = string
}

variable "email" {
  description = "Email address"
  type        = string
}

variable "gitlab_health_check_token" {
  description = "GitLab health check token"
  type        = string
  default     = ""
}

variable "google_project" {
  description = "Google Project name for google dns updater job"
  type        = string
}

variable "nomad_addr" {
  description = "Nomad server address"
  type        = string
}

variable "subnet_cidr" {
  description = "First three octets of subnet"
  type        = string
}

variable "vault_cert_role" {
  description = "Vault PKI role for certificate issue"
  type        = string
}

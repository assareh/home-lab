variable "bound_cidrs" {
  description = "List of IP CIDRs allowed for bootstrap role."
  type        = list(string)
}

variable "gitlab_host" {
  description = "The GitLab host address"
  type        = string
}

variable "kubernetes_ca_cert" {
  description = "The Kubernetes CA Certificate (KUBE_CA_CERT)"
  type        = string
}

variable "kubernetes_host" {
  description = "The Kubernetes host address (KUBE_HOST)"
  type        = string
}

variable "okta_oidc_client_id" {
  description = "The Okta OIDC client ID"
  type        = string
}

variable "okta_oidc_client_secret" {
  description = "The Okta OIDC client secret"
  type        = string
  sensitive   = true
}

variable "okta_oidc_url" {
  description = "The Okta OIDC discovery URL"
  type        = string
}

variable "token_reviewer_jwt" {
  description = "The token reviewer JWT (TOKEN_REVIEW_JWT)"
  type        = string
  sensitive   = true
}
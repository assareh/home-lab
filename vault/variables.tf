variable "kubernetes_ca_cert" {
  description = "The Kubernetes CA Certificate (KUBE_CA_CERT)"
  type        = string
}

variable "kubernetes_host" {
  description = "The Kubernetes host address (KUBE_HOST)"
  type        = string
}

variable "token_reviewer_jwt" {
  description = "The token reviewer JWT (TOKEN_REVIEW_JWT)"
  type        = string
  sensitive   = true
}
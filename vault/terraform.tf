terraform {
  required_version = ">= 1.0.1"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.1.1"
    }
  }
}
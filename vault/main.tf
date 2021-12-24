provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

# this is for the nomad servers, per https://www.nomadproject.io/docs/integrations/vault-integration#token-role-based-integration
resource "vault_token_auth_backend_role" "nomad-cluster" {
  role_name              = "nomad-cluster"
  orphan                 = true
  renewable              = true
  token_explicit_max_ttl = "0"
  token_period           = "259200"

  allowed_policies = [
    "boundary",
    "consul",
    "consul-client-tls",
    "consul-snapshot-agent",
    "fluentd",
    "gitlab-runner",
    "google-dns-updater",
    "homebridge",
    "pki",
    "pihole",
    "prometheus",
    "splunk",
    "telegraf",
    "tfc-agent",
    "tfc-ip-ranges-check",
    "traefik",
    "wireguard"
  ]
}

# add and import approle auth method

# this is used by vault agent during VM creation to bootstrap node secrets
resource "vault_approle_auth_backend_role" "bootstrap" {
  role_name             = "bootstrap"
  secret_id_bound_cidrs = ["192.168.0.101/32", "192.168.0.102/31", "192.168.0.104/31", "192.168.0.106/32"]
  secret_id_num_uses    = "1"
  secret_id_ttl         = "420"
  token_bound_cidrs     = ["192.168.0.101/32", "192.168.0.102/31", "192.168.0.104/31", "192.168.0.106/32"]
  token_period          = "259200"
  token_policies        = ["consul-client-tls", "consul-server-tls", "gcp-kms", "nomad-server", "pki"]
}

# add and import all these policies mentioned here

# for gitlab CI

# this is for k3s vault sidecar injector and devwebapp example
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
  issuer             = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_kubernetes_auth_backend_role" "devweb-app" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "devweb-app"
  bound_service_account_names      = ["internal-app"]
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 86400
  token_policies                   = ["devwebapp"]
}

resource "vault_policy" "devwebapp" {
  name = "devwebapp"

  policy = <<EOT
path "secret/data/devwebapp/config" {
  capabilities = ["read"]
}
EOT
}

resource "vault_mount" "kvv2-secret" {
  path        = "secret"
  type        = "kv-v2"
}

resource "vault_generic_secret" "devwebapp" {
  path = "secret/devwebapp/config"

  data_json = <<EOT
{
  "username": "giraffe",
  "password": "salsa"
}
EOT
}
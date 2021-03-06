provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

locals {
  allowed_policies = concat(local.nomad_jobs, [
    "boundary", # not imported yet
    "consul-client-tls",
    "pki" # not imported yet
  ])
  nomad_jobs = [
    "consul-snapshot-agent",
    "fluentd",
    "gitlab-runner",
    "google-dns-updater",
    "homebridge",
    "pihole",
    "prometheus",
    "splunk",
    "telegraf",
    "tfc-agent",
    "tfc-ip-ranges-check",
    "traefik"
  ]
}

# this is for the nomad servers, per https://www.nomadproject.io/docs/integrations/vault-integration#token-role-based-integration
resource "vault_token_auth_backend_role" "nomad-cluster" {
  role_name              = "nomad-cluster"
  orphan                 = true
  renewable              = true
  token_explicit_max_ttl = "0"
  token_period           = "259200"
  allowed_policies       = local.allowed_policies
}

data "vault_policy_document" "consul-client-tls" {
  rule {
    path         = "pki/int_consul/issue/dc1-client"
    capabilities = ["update"]
  }
}

resource "vault_policy" "consul-client-tls" {
  name   = "consul-client-tls"
  policy = data.vault_policy_document.consul-client-tls.hcl
}

data "vault_policy_document" "consul-server-tls" {
  rule {
    path         = "pki/int_consul/issue/dc1-server"
    capabilities = ["update"]
  }
}

resource "vault_policy" "consul-server-tls" {
  name   = "consul-server-tls"
  policy = data.vault_policy_document.consul-server-tls.hcl
}

data "vault_policy_document" "nomad_jobs" {
  for_each = toset(local.nomad_jobs)

  rule {
    path         = "nomad/data/${each.key}"
    capabilities = ["read"]
  }
}

resource "vault_policy" "nomad_jobs" {
  for_each = toset(local.nomad_jobs)

  name   = each.key
  policy = data.vault_policy_document.nomad_jobs[each.key].hcl
}

# the above are just the policies. the secrets must be created.
# this could be used to create blank secrets
// resource "vault_generic_secret" "nomad_jobs" {
//   depends_on = [vault_mount.kvv2-nomad]
//   for_each   = toset(local.nomad_jobs)

//   path = "nomad/${each.key}"

//   data_json = <<EOT
// {
// }
// EOT
// }

# this is for the bootstrap script
resource "vault_auth_backend" "approle" {
  type = "approle"
}

# this is used by vault agent during VM creation to bootstrap node secrets
resource "vault_approle_auth_backend_role" "bootstrap" {
  backend               = vault_auth_backend.approle.path
  role_name             = "bootstrap"
  secret_id_bound_cidrs = var.bound_cidrs
  secret_id_num_uses    = "1"
  secret_id_ttl         = "420"
  token_bound_cidrs     = var.bound_cidrs
  token_period          = "259200"
  token_policies = [
    "consul-client-tls",
    "consul-server-tls",
    "gcp-kms", # not imported yet
    "nomad-server", # not imported yet
    "pki" # not imported yet
  ]
}

# role id
data "vault_approle_auth_backend_role_id" "role_id" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.bootstrap.role_name
}

output "role-id" {
  value = data.vault_approle_auth_backend_role_id.role_id.role_id
}

# for okta
resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  default_role       = "okta_admin"
  oidc_discovery_url = var.okta_oidc_url
  oidc_client_id     = var.okta_oidc_client_id
  oidc_client_secret = var.okta_oidc_client_secret
  bound_issuer       = var.okta_oidc_url
}

resource "vault_jwt_auth_backend_role" "okta_admin" {
  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = "okta_admin"
  role_type      = "oidc"
  token_policies = ["admin"]
  token_ttl      = "86400"
  oidc_scopes    = ["openid", "profile", "email"]
  user_claim     = "email"

  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://vault.service.consul:8200/ui/vault/auth/oidc/oidc/callback"
  ]

  bound_audiences = [
    var.okta_oidc_client_id,
    "api://vault"
  ]

  bound_claims = {
    groups = "vault_admins"
  }
}

# for gitlab CI
resource "vault_jwt_auth_backend" "jwt" {
  path         = "jwt"
  jwks_url     = "https://${var.gitlab_host}/-/jwks"
  bound_issuer = var.gitlab_host
}

resource "vault_jwt_auth_backend_role" "packer" {
  backend                = vault_jwt_auth_backend.jwt.path
  role_name              = "packer"
  role_type              = "jwt"
  token_explicit_max_ttl = "60"
  token_policies         = ["packer"]
  user_claim             = "user_email"

  bound_claims = {
    project_id = "8"
    ref        = "master"
    ref_type   = "branch"
  }
}

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
  token_policies                   = ["devwebapp"]
  token_ttl                        = 86400
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
  path = "secret"
  type = "kv-v2"
  options = {
    version = "2"
  }
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

# nomad secrets
resource "vault_mount" "kvv2-nomad" {
  path = "nomad"
  type = "kv-v2"
  options = {
    version = "2"
  }
}

# packer secrets
resource "vault_mount" "kvv2-packer" {
  path = "packer"
  type = "kv-v2"
  options = {
    version = "2"
  }
}
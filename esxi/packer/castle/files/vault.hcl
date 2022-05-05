api_addr = "https://ADDRESS:8200"

cluster_addr = "https://ADDRESS:8201"

cluster_name = "castle"

license_path = "/etc/vault.d/license.hclic"

listener "tcp" {
  address = "0.0.0.0:8200"

  tls_cert_file            = "/opt/vault/tls/tls.crt"
  tls_key_file             = "/opt/vault/tls/tls.key"
  tls_disable_client_certs = "true"
}

max_lease_ttl = "8760h"

plugin_directory = "/mnt/data/vault/plugins"

seal "gcpckms" {
  credentials = "you must provide"
  project     = "you must provide"
  region      = "us-west1"
  key_ring    = "vault-keyring"
  crypto_key  = "Vault"
}

storage "consul" {
  address       = "127.0.0.1:8501"
  scheme        = "https"
  tls_ca_file   = "/etc/vault.d/consul-agent-ca.pem"
  tls_cert_file = "/etc/vault.d/dc1-client-consul.pem"
  tls_key_file  = "/etc/vault.d/dc1-client-consul-key.pem"
}

telemetry {
  disable_hostname          = true
  dogstatsd_addr            = "localhost:8125"
  enable_hostname_label     = true
  prometheus_retention_time = "0h"
}

ui = true

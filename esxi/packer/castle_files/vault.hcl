ui = true

max_lease_ttl = "8760h"

license_path = "/etc/vault.d/license.hclic"

listener "tcp" {
  address = "0.0.0.0:8200"

  tls_cert_file            = "/opt/vault/tls/tls.crt"
  tls_key_file             = "/opt/vault/tls/tls.key"
  tls_disable_client_certs = "true"

  proxy_protocol_behavior = "use_always"
}

storage "consul" {}

telemetry {
  disable_hostname = true
  dogstatsd_addr   = "localhost:8125"
}

api_addr = "https://vault.service.consul:8200"

cluster_addr = "https://ADDRESS:8201"

plugin_directory = "/mnt/data/vault/plugins"

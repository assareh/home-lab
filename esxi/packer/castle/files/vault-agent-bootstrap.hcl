pid_file = "./pidfile"

exit_after_auth = true

vault {
  address = "https://vault.service.consul:8200"
  retry {
    num_retries = 3
  }
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path                = "role_id"
      secret_id_file_path              = "secret_id"
      secret_id_response_wrapping_path = "auth/approle/role/bootstrap/secret-id"
    }
  }

  sink "file" {
    config = {
      path = "vault-token-via-agent"
      mode = 0400
    }
  }
}

template { # this is the Vault server cert
  source      = "cert.tpl"
  destination = "tls.crt"
}

template { # this is the Vault server private key
  source      = "key.tpl"
  destination = "tls.key"
}

template { # this is the Consul client cert for Vault storage
  source      = "consul-client-cert.tpl"
  destination = "dc1-client-consul.pem"
}

template { # this is the Consul client key for Vault storage
  source      = "consul-client-key.tpl"
  destination = "dc1-client-consul-key.pem"
}

template { # this is the Consul server cert
  source      = "consul-server-cert.tpl"
  destination = "dc1-server-consul.pem"
}

template { # this is the Consul server private key
  source      = "consul-server-key.tpl"
  destination = "dc1-server-consul-key.pem"
}

// sample for GCP KMS auto unseal credentials
// template {
//   source      = "gcp.tpl"
//   destination = "vault-kms.json"
// }
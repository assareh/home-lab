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

template {
  source      = "cert.tpl"
  destination = "tls.crt"
}

template {
  source      = "key.tpl"
  destination = "tls.key"
}

// sample for GCP KMS auto unseal credentials
// template {
//   source      = "gcp.tpl"
//   destination = "vault-kms.json"
// }
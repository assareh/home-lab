pid_file = "./pidfile"

exit_after_auth = true

vault {
    # 192.168.0.20 when bootstrapping initially
    address = "https://vault.service.consul:8200"
}

auto_auth {
    method {
        type = "approle"
        config = {
            role_id_file_path = "role_id"
            secret_id_file_path = "secret_id"
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

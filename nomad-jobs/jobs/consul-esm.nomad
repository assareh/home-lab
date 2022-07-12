job "consul-ext-service-monitor" {
  datacenters = ["dc1"]

  group "consul-esm" {
    vault {
      policies = ["consul-client-tls"]
    }

    task "consul-esm" {
      driver = "exec"

      artifact {
        source      = "https://releases.hashicorp.com/consul-esm/0.6.0/consul-esm_0.6.0_linux_amd64.zip"
        destination = "local/"

        options {
          checksum = "sha256:161a9df2b69a73e70004aef2908a8fd4cbcd86b3586d892934b3c9e7f6fbea94"
        }
      }

      config {
        command = "local/consul-esm"
        args = ["-config-file",
        "/local/config.hcl"]
      }

      template {
        destination = "secrets/ca.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-esm.client.dc1.consul" }}
{{ .Data.issuing_ca }}{{ end }}
EOF
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-esm.client.dc1.consul" }}
{{ .Data.certificate }}{{ end }}
EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-esm.client.dc1.consul" }}
{{ .Data.private_key }}{{ end }}
EOF
      }

      template {
        data        = <<EOF
ca_file    = "{{ env "NOMAD_SECRETS_DIR" }}/ca.pem"
cert_file  = "{{ env "NOMAD_SECRETS_DIR" }}/cert.pem"
datacenter = "dc1"
http_addr  = "https://consul.service.consul:8501"
key_file   = "{{ env "NOMAD_SECRETS_DIR" }}/key.pem"

critical_threshold = 2
passing_threshold  = 2
EOF
        destination = "/local/config.hcl"
        perms       = "755"
      }

      resources {
        cpu    = 20
        memory = 20
      }
    }
  }
}
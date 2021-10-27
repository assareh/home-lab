job "consul-ext-service-monitor" {
  datacenters = ["dc1"]

  group "consul-esm" {
    vault {
      policies = ["consul-client-tls"]
    }

    task "consul-esm" {
      driver = "exec"

      artifact {
        source      = "https://releases.hashicorp.com/consul-esm/0.5.0/consul-esm_0.5.0_linux_amd64.zip"
        destination = "local/"

        options {
          checksum = "sha256:96dae821bd3d1775048c9dbe8d6112ed645c9b912786c167ba9417f59509059d"
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
        cpu    = 57
        memory = 10
      }

      scaling "cpu" {
        enabled = true
        max     = 500

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        max     = 512

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }
  }
}
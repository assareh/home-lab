variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

job "docker-registry" {
  datacenters = ["dc1"]

  group "docker-registry" {
    network {
      port "https" {
        static = 5000
      }
    }

    vault {
      policies = ["pki"]
    }

    volume "docker_registry" {
      type            = "csi"
      source          = "docker_registry"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    service {
      name = "docker-registry"
      port = "https"

      check {
        type     = "tcp"
        port     = "https"
        interval = "10s"
        timeout  = "2s"
      }

      check {
        name     = "service: docker registry readiness check"
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
        protocol = "https"

        success_before_passing   = "3"
        failures_before_critical = "3"

        check_restart {
          limit = 3
          grace = "60s"
        }
      }
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:2.7.1"
        ports = ["https"]
      }

      env {
        REGISTRY_HTTP_ADDR            = "0.0.0.0:5000"
        REGISTRY_HTTP_TLS_CERTIFICATE = "/secrets/cert.pem"
        REGISTRY_HTTP_TLS_KEY         = "/secrets/key.pem"
      }

      resources {
        cpu    = 150
        memory = 256
      }

      volume_mount {
        volume      = "docker_registry"
        destination = "/var/lib/registry"
      }

      template {
        destination = "/secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=docker-registry.service.consul" $ip_sans }}
{{ .Data.certificate }}{{ end }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=docker-registry.service.consul" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "/secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=docker-registry.service.consul" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      scaling "cpu" {
        enabled = true
        max     = 2000

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        max     = 1024

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }
  }
}


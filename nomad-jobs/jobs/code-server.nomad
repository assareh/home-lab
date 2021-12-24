variable "dns_servers" {
  type = list(string)
}

variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

job "code-server" {
  datacenters = ["dc1"]

  group "code-server" {
    network {
      port "https" {}
    }

    vault {
      policies = ["pki"]
    }

    volume "code_server" {
      type            = "csi"
      source          = "code_server"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "code-server" {
      driver         = "docker"
      kill_timeout   = "45s"
      shutdown_delay = "5s"

      config {
        image       = "docker-registry.service.consul:5000/code-server:3.12.0" # using custom image with my tools and env installed, but codercom/code-server works
        ports       = ["https"]
        dns_servers = var.dns_servers
        args = [
          "--port",
          "${NOMAD_PORT_https}",
          "--cert",
          "/secrets/cert.pem",
          "--cert-key",
          "/secrets/key.pem"
        ]
      }

      volume_mount {
        volume      = "code_server"
        destination = "/home/coder/"
      }

      service {
        name = "code-server"
        port = "https"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.code-server.entryPoints=websecure",
          "traefik.http.routers.code-server.rule=Host(`code-server.${var.domain}`)",
          "traefik.http.routers.code-server.tls=true",
          "traefik.http.services.code-server.loadbalancer.server.scheme=https",
        ]

        check {
          name     = "service: code-server tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "180s"
          }
        }

        check {
          name     = "service: code-server readiness check"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "240s"
          }
        }
      }

      template {
        destination = "/secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=code-server.service.consul" $ip_sans }}
{{ .Data.certificate }}{{ end }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=code-server.service.consul" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "/secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=code-server.service.consul" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      scaling "cpu" {
        enabled = true
        max     = 4000

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
        max     = 4096

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

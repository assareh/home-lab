variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

job "unifi" {
  datacenters = ["dc1"]

  group "unifi" {
    vault {
      policies = ["pki"]
    }

    volume "unifi" {
      type            = "csi"
      source          = "unifi"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    network {
      port "cmdctrl" {
        static = 8080
      }

      port "https" {
        to = 8443
      }

      port "stun" {
        static = 3478
      }
    }

    task "unifi" {
      driver         = "docker"
      shutdown_delay = "5s"

      volume_mount {
        volume      = "unifi"
        destination = "/unifi/data"
        read_only   = false
      }

      volume_mount {
        volume      = "unifi"
        destination = "/unifi/log"
        read_only   = false
      }

      config {
        image = "jacobalberty/unifi:v6.5.54"
        ports = ["cmdctrl", "https", "stun"]
        volumes = [
          "secrets/certs:/unifi/cert",
        ]
      }

      env {
        TZ = "America/Los_Angeles"
      }

      service {
        name = "unifi-cmdctrl"
        port = "cmdctrl"

        check {
          name     = "service: cmdctrl tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      service {
        name = "unifi-stun"
        port = "stun"
      }

      service {
        name = "unifi"
        port = "https"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.unifi.entryPoints=websecure",
          "traefik.http.routers.unifi.rule=Host(`unifi.${var.domain}`)",
          "traefik.http.routers.unifi.tls=true",
          "traefik.http.services.unifi.loadbalancer.server.scheme=https",
        ]

        check {
          type     = "http"
          port     = "https"
          protocol = "https"
          path     = "/status"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      template {
        destination = "secrets/certs/cert.pem"
        perms       = "640"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=unifi.service.consul" "alt_names=unifi.${var.domain}" $ip_sans }}
{{ .Data.certificate }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/privkey.pem"
        perms       = "400"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=unifi.service.consul" "alt_names=unifi.${var.domain}" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/chain.pem"
        perms       = "640"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=unifi.service.consul" "alt_names=unifi.${var.domain}" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      resources {
        cpu    = 60
        memory = 1178
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
        max     = 2048

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

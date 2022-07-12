variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

job "bitbucket" {
  datacenters = ["dc1"]

  group "bitbucket" {
    vault {
      policies = ["pki"]
    }

    network {
      port "http" {
        to = 7990
      }

      port "ssh" {
        to = 7999
      }
    }

    volume "bitbucket_data" {
      type            = "csi"
      source          = "bitbucket_data"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "bitbucket" {
      driver         = "docker"
      kill_timeout   = "45s"
      shutdown_delay = "5s"

      config {
        image = "atlassian/bitbucket-server:7.21.1"
        ports = ["http", "ssh"]
        volumes = [
          "secrets/certs:/etc/bitbucket/ssl",
        ]
      }

      env {
        SERVER_PROXY_NAME = "bitbucket.assareh.com"
        SERVER_PROXY_PORT = "443"
        SERVER_SCHEME     = "https"
        SERVER_SECURE     = "true"
        SEARCH_ENABLED    = "false"
      }

      volume_mount {
        volume      = "bitbucket_data"
        destination = "/var/atlassian/application-data/bitbucket"
      }

      service {
        name = "bitbucket"
        port = "http"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.bitbucket.entryPoints=websecure",
          "traefik.http.routers.bitbucket.rule=Host(`bitbucket.${var.domain}`)",
          "traefik.http.routers.bitbucket.tls=true",
        ]

        check {
          name     = "service: bitbucket tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "300s"
          }
        }
      }

      template {
        destination = "secrets/certs/bitbucket.${var.domain}.crt"
        perms       = "640"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=bitbucket.service.consul" $ip_sans }}
{{ .Data.certificate }}{{ end }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=bitbucket.service.consul" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/bitbucket.${var.domain}.key"
        perms       = "400"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=bitbucket.service.consul" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      resources {
        cpu    = 1897
        memory = 4805
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
        max     = 6144

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

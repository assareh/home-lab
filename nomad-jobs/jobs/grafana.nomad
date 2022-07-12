variable "domain" {
  type    = string
  default = "hashidemos.io"
}

job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    network {
      port "http" {}
    }

    volume "grafana_etc" {
      type            = "csi"
      source          = "grafana_etc"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "grafana_lib" {
      type            = "csi"
      source          = "grafana_lib"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:7.5.5"
        ports = ["http"]
      }

      volume_mount {
        volume      = "grafana_etc"
        destination = "/etc/grafana"
      }

      volume_mount {
        volume      = "grafana_lib"
        destination = "/var/lib/grafana"
      }

      env {
        GF_LOG_LEVEL        = "DEBUG"
        GF_LOG_MODE         = "console"
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
      }

      resources {
        cpu    = 57
        memory = 29
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.grafana.entryPoints=websecure",
          "traefik.http.routers.grafana.rule=Host(`grafana.${var.domain}`)",
          "traefik.http.routers.grafana.tls=true",
        ]

        check {
          type     = "http"
          path     = "/api/health"
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

      scaling "cpu" {
        enabled = true
        max     = 1500

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

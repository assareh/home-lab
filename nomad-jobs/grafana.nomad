job "grafana" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

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

      artifact {
        source      = "git::https://gitlab.hashidemos.io/grafana-dashboards"
        destination = "local/dashboards"
      }

      resources {
        cpu    = 1000
        memory = 256
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.grafana.entryPoints=websecure",
          "traefik.http.routers.grafana.rule=Host(`grafana.hashidemos.io`)",
          "traefik.http.routers.grafana.tls=true",
        ]

        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 1500

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        min     = 128
        max     = 2048

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }
  }
}

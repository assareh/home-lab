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

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:7.5.5"
        ports = ["http"]

        volumes = [
          "/mnt/data/grafana/etc:/etc/grafana",
          "/mnt/data/grafana/lib:/var/lib/grafana",
        ]
      }

      env {
        GF_LOG_LEVEL        = "DEBUG"
        GF_LOG_MODE         = "console"
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
      }

      artifact {
        source      = "git::https://grafana-dashboards"
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

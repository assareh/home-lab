job "internet-monitoring" {
  datacenters = ["dc1"]

  group "internet-monitoring" {
    network {
      port "exporter" {}
    }

    task "speedtest-exporter" {
      driver = "docker"

      config {
        image = "ghcr.io/miguelndecarvalho/speedtest-exporter:v3.3.2"
        ports = ["exporter"]
      }

      env {
        SPEEDTEST_PORT = "${NOMAD_PORT_exporter}"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "prometheus-speedtest-exporter"
        port = "exporter"

        check {
          type     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "2s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 500

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
        min     = 64
        max     = 512

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

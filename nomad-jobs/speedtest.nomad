job "speedtest" {
  datacenters = ["dc1"]

  group "speedtest" {
    network {
      port "http" {
        static = 8001
        to     = 80
      }
    }

    service {
      name = "speedtest"
      port = "http"

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.http.routers.speedtest.entryPoints=websecure",
        "traefik.http.routers.speedtest.rule=Host(`speedtest.hashidemos.io`)",
        "traefik.http.routers.speedtest.tls=true",
      ]

      check {
        type     = "http"
        port     = "http"
        path     = "/"
        interval = "15s"
        timeout  = "2s"
      }
    }

    task "speedtest" {
      driver = "docker"

      config {
        image = "adolfintel/speedtest:5.2.4"
        ports = ["http"]
      }

      resources {
        cpu    = 57
        memory = 66
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

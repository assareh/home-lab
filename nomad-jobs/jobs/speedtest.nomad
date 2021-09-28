job "speedtest" {
  datacenters = ["dc1"]

  priority = 10

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

    task "speedtest" {
      driver = "docker"

      config {
        image = "adolfintel/speedtest:5.2.4"
        ports = ["http"]
      }

      resources {
        cpu    = 57
        memory = 14
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

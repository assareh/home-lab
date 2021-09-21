job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"

      port "api" {}
    }

    service {
      name = "count-api"
      port = "api"

      connect {
        sidecar_service {
          tags = [
            "traefik.enable=false",
          ]
        }
      }
    }

    task "counter" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v1"
      }

      env {
        PORT = "${NOMAD_PORT_api}"
      }

      resources {
        cpu    = 57
        memory = 10
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

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {}
    }

    service {
      name = "countdash"
      port = "http"

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.http.routers.countdash.entryPoints=websecure",
        "traefik.http.routers.countdash.rule=Host(`countdash.hashidemos.io`)",
        "traefik.http.routers.countdash.tls=true",
      ]

      connect {
        sidecar_service {

          tags = [
            "traefik.enable=false",
          ]

          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 9001
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
        PORT                 = "${NOMAD_PORT_http}"
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }

      resources {
        cpu    = 57
        memory = 10
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

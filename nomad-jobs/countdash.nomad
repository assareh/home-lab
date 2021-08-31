job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9003"

      connect {
        sidecar_service {}
      }
    }

    task "counter" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v1"
      }

      env {
        PORT = 9003
      }

      resources {
        cpu    = 100
        memory = 128
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

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        static = 9002
        to     = 9002
      }
    }

    service {
      name = "countdash"
      port = "9002"

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.countdash.entryPoints=websecure",
        "traefik.http.routers.countdash.rule=Host(`countdash.hashidemos.io`)",
        "traefik.http.routers.countdash.tls=true",
      ]

      connect {
        sidecar_service {
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
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }

      resources {
        cpu    = 100
        memory = 128
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

variable "domain" {
  type    = string
  default = "hashidemos.io"
}

job "speedtest" {
  datacenters = ["dc1"]

  priority = 10

  group "speedtest" {
    network {
      mode = "bridge"

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
        #        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.speedtest.entryPoints=websecure",
        "traefik.http.routers.speedtest.rule=Host(`speedtest.${var.domain}`)",
        "traefik.http.routers.speedtest.tls=true",
      ]

      // connect {
      //   sidecar_service {}
      // }

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
        image = "adolfintel/speedtest"
        ports = ["http"]
      }

      resources {
        cpu    = 20
        memory = 56
      }
    }
  }
}

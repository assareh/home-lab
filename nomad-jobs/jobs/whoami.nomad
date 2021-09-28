job "whoami" {
  datacenters = ["dc1"]

  group "whoami" {
    count = 2

    network {
      mode = "bridge"

      port "web" {}
    }

    service {
      name = "whoami"
      port = "web"

      connect {
        sidecar_service {}
      }

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.whoami.entryPoints=websecure",
        "traefik.http.routers.whoami.rule=Host(`whoami.hashidemos.io`)",
        "traefik.http.routers.whoami.tls=true",
      ]

      check {
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "31s"
      }
    }

    task "whoami" {
      driver = "docker"

      config {
        image = "traefik/whoami"
        ports = ["web"]
        args  = ["--port", "${NOMAD_PORT_web}"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
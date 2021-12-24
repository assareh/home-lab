variable "domain" {
  type    = string
  default = "hashidemos.io"
}

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
        "traefik.http.routers.whoami.rule=Host(`whoami.${var.domain}`)",
        "traefik.http.routers.whoami.tls=true",
      ]

      check {
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"
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
        cpu    = 35
        memory = 128
      }
    }
  }
}
job "node-exporter" {
  datacenters = ["dc1"]
  type        = "system"

  priority = 10

  group "node-exporter" {
    network {
      port "http" {
        static = 9100
      }
    }

    service {
      name = "node-exporter"
      port = "http"

      check {
        type     = "http"
        port     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "31s"

        check_restart {
          limit = 3
          grace = "60s"
        }
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter"
        ports = ["http"]

        args = [
          "--path.procfs=/host/proc",
          "--path.sysfs=/host/sys",
          "--collector.filesystem.ignored-mount-points",
          "^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)"
        ]

        volumes = [
          "/proc:/host/proc:ro",
          "/sys:/host/sys:ro",
          "/:/rootfs:ro"
        ]
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

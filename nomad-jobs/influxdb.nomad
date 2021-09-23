job "influxdb" {
  datacenters = ["dc1"]

  group "influxdb" {
    network {
      port "http" {
        static = 8086
      }
    }

    volume "influxdb" {
      type            = "csi"
      source          = "influxdb"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "influxdb" {
      driver = "docker"

      volume_mount {
        volume      = "influxdb"
        destination = "/var/lib/influxdb"
      }

      config {
        image = "influxdb:1.8"
        ports = ["http"]
      }

      env {
        TZ = "America/Los_Angeles"
      }

      resources {
        cpu    = 804
        memory = 1353
      }

      service {
        name = "influxdb"
        port = "http"

        check {
          type     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "31s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }


      scaling "cpu" {
        enabled = true
        max     = 1500

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
        max     = 2048

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
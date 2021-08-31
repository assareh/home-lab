job "influxdb" {
  datacenters = ["dc1"]

  group "influxdb" {
    network {
      port "http" {
        static = 8086
        to     = 8086
      }
    }

    volume "influxdb" {
      type      = "host"
      read_only = false
      source    = "influxdb"
    }

    task "influxdb" {
      driver = "docker"

      volume_mount {
        volume      = "influxdb"
        destination = "/var/lib/influxdb"
        read_only   = false
      }

      config {
        image = "influxdb:1.8"
        ports = ["http"]
      }

      env {
        TZ = "America/Los_Angeles"
      }

      resources {
        cpu    = 500
        memory = 500
      }

      service {
        name = "influxdb"
        port = "http"

        check {
          type     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "2s"
        }
      }


      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 1500

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
        min     = 128
        max     = 2048

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
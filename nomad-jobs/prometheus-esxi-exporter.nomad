job "prometheus-esxi-exporter" {
  datacenters = ["dc1"]

  group "prometheus-esxi-exporter" {
    network {
      port "exporter" {
        static = 9512
        to     = 9512
      }
    }

    service {
      name = "prometheus-esxi-exporter"
      port = "exporter"

      check {
        type     = "http"
        path     = "/"
        interval = "5s"
        timeout  = "2s"

        check_restart {
          limit = 3
          grace = "60s"
        }
      }
    }

    vault {
      policies = ["prometheus"]
    }

    task "prometheus-esxi-exporter" {
      driver = "docker"

      config {
        image = "devinotelecom/prometheus-vmware-exporter"
        ports = ["exporter"]
      }

      env {
        ESX_HOST     = "192.168.10.6"
        ESX_USERNAME = "prometheus"
        ESX_LOG      = "debug"
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

      template {
        data = <<EOH
                   ESX_PASSWORD="{{with secret "nomad/data/prometheus"}}{{.Data.data.ESX_PASSWORD}}{{end}}"
                   EOH

        destination = "secrets/config.env"
        env         = true
      }
    }
  }
}

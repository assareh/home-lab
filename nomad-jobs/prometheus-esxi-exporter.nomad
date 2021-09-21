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
        interval = "10s"
        timeout  = "31s"

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
        ESX_HOST     = "esxi.service.consul"
        ESX_USERNAME = "prometheus"
        ESX_LOG      = "debug"
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
          evaluation_interval = "1h"

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
          evaluation_interval = "1h"

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

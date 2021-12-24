job "prometheus-esxi-exporter" {
  datacenters = ["dc1"]

  group "prometheus-esxi-exporter" {
    network {
      port "exporter" {
        static = 9512
      }
    }

    service {
      name = "prometheus-esxi-exporter"
      port = "exporter"

      check {
        type     = "http"
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
        cpu    = 20
        memory = 12
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

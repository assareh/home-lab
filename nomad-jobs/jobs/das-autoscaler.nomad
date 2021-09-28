job "das-autoscaler" {
  datacenters = ["dc1"]

  priority = 5

  group "autoscaler" {
    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler-enterprise:0.3.3"
        command = "bin/nomad-autoscaler"

        args = [
          "agent",
          "-config",
          "${NOMAD_TASK_DIR}/autoscaler.hcl",
          "-http-bind-address",
          "0.0.0.0",
        ]

        ports = ["http"]
      }

      template {
        destination = "${NOMAD_TASK_DIR}/autoscaler.hcl"

        data = <<EOH
apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "{{ with service "prometheus" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"
  }
}

nomad {
  address = "{{ with service "nomad-client" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"
  namespace = "*"
}

policy_eval {
  workers = {
    cluster    = 0
    horizontal = 0
  }
}
EOH
      }

      resources {
        cpu    = 1322
        memory = 146
      }

      scaling "cpu" {
        enabled = true
        max     = 2000

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
        max     = 1024

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name = "nomad-autoscaler"
      port = "http"

      check {
        type     = "http"
        path     = "/v1/health"
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
  }
}

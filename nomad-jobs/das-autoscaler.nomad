job "das-autoscaler" {
  datacenters = ["dc1"]

  group "autoscaler" {
    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler-enterprise:0.3.2"
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
log_level = "debug"

nomad {
  address = "{{ with service "nomad-client" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"
  namespace = "*"
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "{{ with service "prometheus" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"
  }
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
        cpu    = 1024
        memory = 512
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 2000

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
        max     = 1024

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

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
        interval = "5s"
        timeout  = "2s"
      }
    }
  }
}

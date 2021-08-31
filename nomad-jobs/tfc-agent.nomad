job "tfc-agent" {
  datacenters = ["dc1"]
  type        = "service"

  group "tfc-agent" {
    count = 2

    vault {
      policies = ["tfc-agent"]
    }

    task "tfc-agent" {
      driver = "exec"

      artifact {
        source = "https://releases.hashicorp.com/tfc-agent/0.2.1/tfc-agent_0.2.1_linux_amd64.zip"

        options {
          checksum = "sha256:ae3394688ff0d2102f3e2940ffbdba6b538b34a3d112a80e3d2f441d29b76b82"
        }
      }

      config {
        command = "tfc-agent"
      }

      env {
        TFC_AGENT_SINGLE = "true"
        TFC_AGENT_NAME   = "Castle"
      }

      template {
        data = <<EOH
                   TFC_AGENT_TOKEN="{{with secret "nomad/data/tfc-agent"}}{{.Data.data.TFC_AGENT_TOKEN_ANGRYHIPPO}}{{end}}"
                   EOH

        destination = "secrets/config.env"
        env         = true
      }

      resources {
        cpu    = 2000
        memory = 2048
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
        min     = 128
        max     = 2048

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "99"
            }
          }
        }
      }
    }
  }
}

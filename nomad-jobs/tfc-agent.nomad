job "tfc-agent" {
  datacenters = ["dc1"]
  type        = "service"

  group "tfc-agent" {
    restart {
      attempts = 100
      delay    = "1s"
    }

    vault {
      policies = ["tfc-agent"]
    }

    task "tfc-agent" {
      driver = "exec"

      artifact {
        source = "https://releases.hashicorp.com/tfc-agent/0.4.0/tfc-agent_0.4.0_linux_amd64.zip"

        options {
          checksum = "sha256:bb9db0edc2932b753128b61243cd772196fd8ecfc67545b7c193932bcbdaf3cc"
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
        cpu    = 57
        memory = 345
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
        max     = 2048

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

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

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
        source = "https://releases.hashicorp.com/tfc-agent/1.1.0/tfc-agent_1.1.0_linux_amd64.zip"

        options {
          checksum = "sha256:1baf4ec65eac52829a5db88ba6099977e2aa0416598a20b6875a2c0be41846d1"
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
        memory = 512
      }

      scaling "cpu" {
        enabled = true
        max     = 2000

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }
    }
  }
}

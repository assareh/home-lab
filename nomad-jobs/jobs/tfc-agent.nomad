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
        source = "https://releases.hashicorp.com/tfc-agent/1.0.1/tfc-agent_1.0.1_linux_amd64.zip"

        options {
          checksum = "sha256:0cb56f9e39842e167ca790a8eb5030cab3cb74caae3abe63e272de4a286625f6"
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
        cpu    = 200
        memory = 345
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

      scaling "mem" {
        enabled = true
        max     = 2048

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

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

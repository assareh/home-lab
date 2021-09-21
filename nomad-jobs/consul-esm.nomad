job "consul-esm" {
  datacenters = ["dc1"]

  group "consul-esm" {
    task "consul-esm" {
      driver = "exec"

      artifact {
        source      = "https://releases.hashicorp.com/consul-esm/0.5.0/consul-esm_0.5.0_linux_amd64.zip"
        destination = "local/"

        options {
          checksum = "sha256:96dae821bd3d1775048c9dbe8d6112ed645c9b912786c167ba9417f59509059d"
        }
      }

      config {
        command = "local/consul-esm"
      }

      resources {
        cpu    = 57
        memory = 11
      }

      scaling "cpu" {
        enabled = true
        max     = 500

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
        max     = 512

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }
  }
}
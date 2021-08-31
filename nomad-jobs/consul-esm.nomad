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
    }
  }
}
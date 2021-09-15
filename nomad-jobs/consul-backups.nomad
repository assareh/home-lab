job "consul-backups" {
  datacenters = ["dc1"]

  group "consul-snapshot" {
    vault {
      policies = ["consul-snapshot-agent"]
    }

    volume "consul_snapshots" {
      type            = "csi"
      source          = "consul_snapshots"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "consul-snapshot" {
      volume_mount {
        volume      = "consul_snapshots"
        destination = "/consul_snapshots"
      }

      constraint {
        attribute = "${node.class}"
        value     = "castle"
      }

      driver = "exec"

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

      template {
        destination = "secrets/consul-agent.env"
        env         = true

        data = <<EOF
CONSUL_LICENSE="{{with secret "nomad/data/consul-snapshot-agent"}}{{.Data.data.consul_license}}{{end}}"
EOF
      }

      template {
        data        = <<EOF
{
  "snapshot_agent": {
    "datacenter": "dc1",
    "snapshot": {
      "interval": "24h",
      "retain": 30
    },
    "local_storage": {
      "path": "/consul_snapshots"
    }
  }
}
EOF
        destination = "/local/agent_config.json"
        perms       = "755"
      }

      template {
        data        = <<EOF
#!/bin/bash
/usr/bin/consul snapshot agent -config-file /local/agent_config.json
EOF
        destination = "/local/consul-snapshot-run.sh"
        perms       = "755"
      }

      config {
        command = "bash"
        args    = ["/local/consul-snapshot-run.sh"]
      }
    }
  }
}

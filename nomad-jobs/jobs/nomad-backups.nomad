job "nomad-backups" {
  datacenters = ["dc1"]

  group "nomad-snapshot" {
    volume "nomad_snapshots" {
      type            = "csi"
      source          = "nomad_snapshots"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "nomad-snapshot" {
      volume_mount {
        volume      = "nomad_snapshots"
        destination = "/nomad-snapshots/"
      }

      constraint {
        attribute = "${node.class}"
        value     = "castle"
      }

      driver = "exec"

      resources {
        cpu    = 57
        memory = 16
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

      template {
        data        = <<EOF
nomad {
  address = "http://127.0.0.1:4646"
}

snapshot {
  interval         = "24h"
  retain           = 30
  stale            = false
  service          = "nomad-snapshot"
  deregister_after = "72h"
  lock_key         = "nomad-snapshot/lock"
  max_failures     = 3
  prefix           = "nomad"
}

log {
  level           = "INFO"
  enable_syslog   = false
  syslog_facility = "LOCAL0"
}

consul {
  enabled   = true
  http_addr = "127.0.0.1:8500"
}

local_storage {
  path = "/nomad-snapshots/"
}
EOF
        destination = "/local/agent_config.hcl"
        perms       = "755"
      }

      template {
        data        = <<EOF
#!/bin/bash
/usr/bin/nomad operator snapshot agent /local/agent_config.hcl
EOF
        destination = "/local/nomad-snapshot-run.sh"
        perms       = "755"
      }

      config {
        command = "bash"
        args    = ["/local/nomad-snapshot-run.sh"]
      }
    }
  }
}

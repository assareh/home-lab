job "consul-backups" {
  datacenters = ["dc1"]

  group "consul-snapshot" {

    volume "consul-snapshots" {
      type      = "host"
      read_only = false
      source    = "consul-snapshots"
    }

    task "consul-snapshot" {

      volume_mount {
        volume      = "consul-snapshots"
        destination = "/consul-snapshots/"
        read_only   = false
      }

      constraint {
        attribute = "$${node.class}"
        value     = "castle"
      }

      driver = "exec"

      template {
        data        = <<EOH
  ${config}
  EOH
        destination = "/local/agent_config.json"
        perms       = "755"
      }

      template {
        data        = <<EOH
  #!/bin/bash
  /usr/bin/consul snapshot agent -config-file /local/agent_config.json
  EOH
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

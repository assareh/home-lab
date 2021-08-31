job "nomad-backups" {
  datacenters = ["dc1"]

  group "nomad-snapshot" {

    volume "nomad-snapshots" {
      type      = "host"
      read_only = false
      source    = "nomad-snapshots"
    }

    task "nomad-snapshot" {

      volume_mount {
        volume      = "nomad-snapshots"
        destination = "/nomad-snapshots/"
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
        destination = "/local/agent_config.hcl"
        perms       = "755"
      }

      template {
        data        = <<EOH
  #!/bin/bash
  /tmp/nomad_1.0.3+ent/nomad operator snapshot agent /local/agent_config.hcl
  EOH
        destination = "/local/nomad-snapshot-run.sh"
        perms       = "755"
      }

      artifact { # bug in snapshot agent 1.0.4
        source      = "https://releases.hashicorp.com/nomad/1.0.3+ent/nomad_1.0.3+ent_linux_amd64.zip"
        destination = "/tmp/nomad_1.0.3+ent/"
      }

      config {
        command = "bash"
        args    = ["/local/nomad-snapshot-run.sh"]
      }
    }
  }
}

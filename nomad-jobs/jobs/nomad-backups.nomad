job "nomad-backups" {
  datacenters = ["dc1"]

  group "nomad-snapshot" {
    vault {
      policies = ["consul-client-tls"]
    }

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
        cpu    = 20
        memory = 16
      }

      template {
        destination = "secrets/ca.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=nomad-snapshot-agent.client.dc1.consul" }}
{{ .Data.issuing_ca }}{{ end }}
EOF
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=nomad-snapshot-agent.client.dc1.consul" }}
{{ .Data.certificate }}{{ end }}
EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=nomad-snapshot-agent.client.dc1.consul" }}
{{ .Data.private_key }}{{ end }}
EOF
      }

      template {
        data        = <<EOF
nomad {
  address = "http://localhost:4646"
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
  ca_file    = "{{ env "NOMAD_SECRETS_DIR" }}/ca.pem"
  cert_file  = "{{ env "NOMAD_SECRETS_DIR" }}/cert.pem"
  datacenter = "dc1"
  http_addr  = "https://consul.service.consul:8501"
  key_file   = "{{ env "NOMAD_SECRETS_DIR" }}/key.pem"
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

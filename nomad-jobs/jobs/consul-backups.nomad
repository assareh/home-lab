job "consul-backups" {
  datacenters = ["dc1"]

  group "consul-snapshot" {
    vault {
      policies = ["consul-client-tls", "consul-snapshot-agent"]
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
        cpu    = 20
        memory = 27
      }

      template {
        destination = "secrets/ca.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-snapshot-agent.client.dc1.consul" }}
{{ .Data.issuing_ca }}{{ end }}
EOF
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-snapshot-agent.client.dc1.consul" }}
{{ .Data.certificate }}{{ end }}
EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=consul-snapshot-agent.client.dc1.consul" }}
{{ .Data.private_key }}{{ end }}
EOF
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
    "http_addr": "https://consul.service.consul:8501",
    "datacenter": "dc1",
    "ca_file": "{{ env "NOMAD_SECRETS_DIR" }}/ca.pem",
    "cert_file": "{{ env "NOMAD_SECRETS_DIR" }}/cert.pem",
    "key_file": "{{ env "NOMAD_SECRETS_DIR" }}/key.pem",
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

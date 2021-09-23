job "fluentd" {
  datacenters = ["dc1"]
  type        = "system"

  group "fluentd" {
    network {
      port "fluentd" {
        static = 24224
      }
    }

    vault {
      policies = ["fluentd"]
    }

    update {
      stagger      = "10s"
      max_parallel = 1
    }

    task "fluentd" {
      driver = "docker"

      config {
        image = "assareh/fluentd-splunk-hec:v1.14-debian-1"
        ports = ["fluentd"]

        volumes = [
          "local/config/fluentd.conf:/fluentd/etc/fluent.conf",
          "/var/log/vault_audit.log:/var/log/vault_audit.log",
          "/var/log/vault_audit.pos:/var/log/vault_audit.pos",
        ]
      }

      template {
        data = <<EOF
<source>
  @type tail
  path /var/log/vault_audit.log
  pos_file /var/log/vault_audit.pos
  <parse>
    @type json
    time_format %iso8601
  </parse>
  tag vault_audit
</source>

<filter vault_audit>
  @type record_transformer
  <record>
    cluster v5
  </record>
</filter>

<match vault_audit.**>
  @type splunk_hec
  host splunk.service.consul
  port 8088
  token {{with secret "nomad/data/fluentd"}}{{.Data.data.SPLUNK_TOKEN}}{{end}}
</match>
EOF

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/fluentd.conf"
      }

      resources {
        cpu    = 172
        memory = 256
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

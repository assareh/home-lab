job "telegraf" {
  datacenters = ["dc1"]
  type        = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "telegraf" {
    task "telegraf" {
      driver = "docker"

      config {
        network_mode = "host"
        image        = "telegraf:1.18.1-alpine"

        args = [
          "-config",
          "/local/telegraf.conf",
        ]
      }

      template {
        data = <<EOTC
# Telegraf Configuration
#
# Accepts statsd connections on port 8125.
# Sends output to InfluxDB at http://influxdb.service.consul:8086.

# Adding Client class
# This should be here until https://github.com/hashicorp/nomad/pull/3882 is merged
{{ $node_class := env "node.class" }}
[global_tags]{{ if $node_class }}
  nomad_client_class = "{{ env "node.class" }}"{{else}}
  nomad_client_class = "none"{{ end }}
  role = "consul-server"
  datacenter = "dc1"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "3s"
  precision = ""
  debug = false
  quiet = false
  hostname = ""
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://influxdb.service.consul:8086"]
  database = "telegraf"
  retention_policy = "autogen"
  timeout = "5s"
  username = "telegraf"
  password = "telegraf"
  user_agent = "telegraf-{{env "NOMAD_TASK_NAME" }}"

[[inputs.consul]]
  address = "{{ env "attr.unique.network.ip-address" }}:8500"
  scheme = "http"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false

[[inputs.disk]]
  # mount_points = ["/"]
  # ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.diskio]]
  # devices = ["sda", "sdb"]
  # skip_serial_number = false

[[inputs.kernel]]
  # no configuration

[[inputs.linux_sysctl_fs]]
  # no configuration

[[inputs.mem]]
  # no configuration

[[inputs.net]]
  interfaces = ["ens*"]

[[inputs.netstat]]
  # no configuration

[[inputs.processes]]
  # no configuration

[[inputs.procstat]]
  pattern = "(consul|vault)"

[[inputs.prometheus]]
  urls = ["http://{{ env "attr.unique.network.ip-address" }}:4646/v1/metrics?format=prometheus"]

[[inputs.swap]]
  # no configuration

[[inputs.system]]
  # no configuration

[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  delete_gauges = true
  delete_counters = true
  delete_sets = true
  delete_timings = true
  percentiles = [90]
  metric_separator = "."
  parse_data_dog_tags = true
  allowed_pending_messages = 10000
  percentile_limit = 1000
EOTC

        destination = "local/telegraf.conf"
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

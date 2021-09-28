job "telegraf" {
  datacenters = ["dc1"]
  type        = "system"

  group "telegraf" {
    vault {
      policies = ["telegraf"]
    }

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

# Global tags relate to and are available for use in Splunk searches
# Of particular note are the index tag, which is required to match the
# configured metrics index name and the cluster tag which should match the
# value of Vault's cluster_name configuration option value.
[global_tags]
  index      = "vault-metrics"
  datacenter = "dc1"
  role       = "vault-server"
  cluster    = "castle"

# Agent options around collection interval, sizes, jitter and so on
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false

# An input plugin that listens on UDP/8125 for statsd compatible telemetry
# messages using Datadog extensions which are emitted by Vault
[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  datadog_extensions = true
  delete_gauges = true
  delete_counters = true
  delete_sets = true
  delete_timings = true
  percentiles = [90]
  metric_separator = "."
  parse_data_dog_tags = true
  allowed_pending_messages = 10000
  percentile_limit = 1000

# An output plugin that can transmit metrics over HTTP to Splunk
# You must specify a valid Splunk HEC token as the Authorization value
[[outputs.http]]
  url = "http://splunk.service.consul:8088/services/collector"
  data_format="splunkmetric"
  splunkmetric_hec_routing=true
  [outputs.http.headers]
    Content-Type = "application/json"
    Authorization = "Splunk {{with secret "nomad/data/telegraf"}}{{.Data.data.SPLUNK_TOKEN}}{{end}}"
  
[[outputs.influxdb]]
  urls = ["http://influxdb.service.consul:8086"] # required
  database = "telegraf" # required
  retention_policy = ""
  write_consistency = "any"
  timeout = "5s"
  username = "telegraf"
  password = "telegraf"

# Read metrics about cpu usage using default configuration values
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

# Read metrics about memory usage
[[inputs.mem]]
  # No configuration required

# Read metrics about network interface usage
[[inputs.net]]
  # Specify an interface or all
  interfaces = ["ens160"]

# Read metrics about swap memory usage
[[inputs.swap]]
  # No configuration required

# Read metrics about disk usage using default configuration values
[[inputs.disk]]
  ## By default stats will be gathered for all mount points.
  ## Set mount_points will restrict the stats to only the specified mount points.
  ## mount_points = ["/"]
  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
 
[[inputs.diskio]]
  # devices = ["sda", "sdb"]
  # skip_serial_number = false

[[inputs.kernel]]
  # no configuration required

[[inputs.linux_sysctl_fs]]
  # no configuration required

[[inputs.netstat]]
  # no configuration required

[[inputs.processes]]
  # no configuration required

[[inputs.procstat]]
  pattern = "(consul|vault)"

[[inputs.system]]
  # no configuration required

[[inputs.consul]]
  address = "localhost:8500"
  scheme = "http"
EOTC

        destination = "local/telegraf.conf"
      }

      resources {
        cpu    = 172
        memory = 246
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

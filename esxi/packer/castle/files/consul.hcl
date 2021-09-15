# Full configuration options can be found at https://www.consul.io/docs/agent/options.html

advertise_addr = "{{ GetInterfaceIP `ens160` }}"

autopilot {
  upgrade_version_tag = "build"
}

bootstrap_expect = 3

client_addr = "0.0.0.0"

connect {
  enabled = true
}

data_dir = "/opt/consul"

enable_local_script_checks = true

encrypt = ""

license_path = "/etc/consul.d/license.hclic"

log_level = "INFO"

node_meta {
  build = "0.0.0"
}

ports {
  grpc = 8502
  http = 8500
}

retry_join = ["192.168.0.101", "192.168.0.102", "192.168.0.103", "192.168.0.104", "192.168.0.105", "192.168.0.106"]

server = true

telemetry {
  disable_hostname          = true
  dogstatsd_addr            = "localhost:8125"
  prometheus_retention_time = "30s"
}

ui_config {
  enabled = true
}
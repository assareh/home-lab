# Full configuration options can be found at https://www.consul.io/docs/agent/options.html

server = true

license_path = "/etc/consul.d/license.hclic"

bootstrap_expect = 3

data_dir = "/opt/consul"

log_level = "INFO"

enable_local_script_checks = true

advertise_addr = "{{ GetInterfaceIP `ens160` }}"

client_addr = "0.0.0.0"

retry_join = ["192.168.0.101", "192.168.0.102", "192.168.0.103", "192.168.0.104", "192.168.0.105", "192.168.0.106"]

autopilot {
  upgrade_version_tag = "build"
}

connect {
  enabled = true
}

node_meta {
  build = "0.0.7"
}

ports {
  grpc = 8502
  http = 8500
}

telemetry {
  disable_hostname = true
  dogstatsd_addr   = "localhost:8125"
}

ui_config {
  enabled = true
}

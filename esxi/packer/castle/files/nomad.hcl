# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

bind_addr = "0.0.0.0"

data_dir = "/opt/nomad"

leave_on_terminate = true

log_level = "INFO"

advertise {
  http = "{{ GetInterfaceIP `ens160` }}"
  rpc  = "{{ GetInterfaceIP `ens160` }}"
  serf = "{{ GetInterfaceIP `ens160` }}"
}

autopilot {
  cleanup_dead_servers      = true
  disable_upgrade_migration = false
  enable_custom_upgrades    = true
  enable_redundancy_zones   = false
  last_contact_threshold    = "200ms"
  max_trailing_logs         = 250
  server_stabilization_time = "10s"
}

client {
  enabled    = true
  node_class = "castle"
}

plugin "containerd-driver" {
  config {
    enabled            = true
    containerd_runtime = "io.containerd.runc.v2"
  }
}

plugin "docker" {
  config {
    allow_caps = ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "NET_ADMIN",
    "NET_BIND_SERVICE", "NET_BROADCAST", "NET_RAW", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
    allow_privileged = true # required for NFS CSI Plugin
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

server {
  enabled          = true
  bootstrap_expect = 3
  encrypt          = ""
  license_path     = "/etc/nomad.d/license.hclic"
  raft_protocol    = 3
  upgrade_version  = "0.0.0"
}

telemetry {
  datadog_address            = "localhost:8125"
  datadog_tags               = ["role:castle"]
  disable_hostname           = true
  prometheus_metrics         = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

vault {
  enabled          = true
  address          = "https://vault.service.consul:8200"
  create_from_role = "nomad-cluster"
}

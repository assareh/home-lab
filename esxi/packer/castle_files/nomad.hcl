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

autopilot {}

client {
  enabled    = true
  node_class = "castle"

  host_volume "nomad-snapshots" {
    path      = "/mnt/data/nomad-snapshots"
    read_only = false
  }

  host_volume "consul-snapshots" {
    path      = "/mnt/data/consul-snapshots"
    read_only = false
  }

  host_volume "influxdb" {
    path      = "/mnt/data/influxdb"
    read_only = false
  }

  host_volume "unifi" {
    path      = "/mnt/data/unifi"
    read_only = false
  }
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

    volumes {
      enabled = true
    }
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

server {
  enabled          = true
  license_path     = "/etc/nomad.d/license.hclic"
  bootstrap_expect = 3
  raft_protocol    = 3
}

telemetry {
  disable_hostname           = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
  statsd_address             = "localhost:8125"
}

vault {
  enabled = true
  address = "https://vault.service.consul:8200"
}

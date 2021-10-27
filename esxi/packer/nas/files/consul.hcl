auto_encrypt = {
  tls = true
}

bind_addr = "{{ GetInterfaceIP `ens160` }}"

ca_file = "/etc/consul.d/consul-agent-ca.pem"

connect {
  enabled = true
}

datacenter = "dc1"

data_dir = "/opt/consul/data"

enable_local_script_checks = true

encrypt = ""

log_level = "INFO"

ports {
  http = -1
  https = 8501
}

primary_datacenter = "dc1"

retry_join = ["consul.service.consul"]

verify_incoming = false

verify_outgoing = true

verify_server_hostname = true
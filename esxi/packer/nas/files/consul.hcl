bind_addr = "{{ GetInterfaceIP `ens160` }}"

connect {
  enabled = true
}

data_dir = "/opt/consul/data"

enable_local_script_checks = true

encrypt = ""

log_level = "INFO"

retry_join = ["consul.service.consul"]
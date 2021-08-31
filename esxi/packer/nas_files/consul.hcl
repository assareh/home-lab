data_dir = "/opt/consul/data"

bind_addr = "{{ GetInterfaceIP `ens160` }}"

retry_join = ["consul.service.consul"]

log_level = "INFO"

enable_local_script_checks = true

connect {
  enabled = true
}

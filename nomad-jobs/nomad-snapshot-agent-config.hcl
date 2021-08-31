nomad {
  address = "http://127.0.0.1:4646"
}

snapshot {
  interval         = "24h"
  retain           = 30
  stale            = false
  service          = "nomad-snapshot"
  deregister_after = "72h"
  lock_key         = "nomad-snapshot/lock"
  max_failures     = 3
  prefix           = "nomad"
}

log {
  level           = "INFO"
  enable_syslog   = false
  syslog_facility = "LOCAL0"
}

consul {
  enabled   = true
  http_addr = "127.0.0.1:8500"
}

local_storage {
  path = "/nomad-snapshots/"
}

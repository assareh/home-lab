consul {
  address = "127.0.0.1:8500"
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
  }
}

template {
  source = "/etc/nginx/nginx.conf.ctmpl"
  destination = "/etc/nginx/nginx.conf"
  command = "service nginx reload"
  perms = 0644
}

template {
  source = "/etc/nginx/conf.d/dns.conf.ctmpl"
  destination = "/etc/nginx/conf.d/dns.conf"
  command = "service nginx reload"
  perms = 0644
}

syslog {
  enabled = true
  facility = "LOCAL5"
}
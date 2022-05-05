variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "subnet_cidr" {
  type    = string
  default = "192.168.0"
}

job "pihole" {
  datacenters = ["dc1"]

  priority = 90

  update {
    auto_revert  = true
    auto_promote = true
    canary       = 1
    stagger      = "60s"
  }

  vault {
    policies = ["pihole"]
  }

  group "pihole" {
    count          = 2
    shutdown_delay = "5s"

    network {
      port "cloudflared" {}

      port "dns" {
        static = 53
      }

      port "http" {}

      port "prometheus_cloudflared_metrics" {}

      port "prometheus_pihole_exporter" {}
    }

    restart {
      attempts = 2
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    task "pihole" {
      driver = "docker"

      config {
        image        = "pihole/pihole:2022.02.1"
        network_mode = "host"
        volumes = [
          "local/etc-dnsmasq.d/00-custom.conf:/etc/dnsmasq.d/00-custom.conf",
          "local/pihole:/etc/pihole",
        ]
      }

      env {
        DNSSEC        = "true"
        INTERFACE     = "ens160"
        PIHOLE_DNS_   = "${attr.unique.network.ip-address}#${NOMAD_PORT_cloudflared}"
        QUERY_LOGGING = "true"
        TZ            = "America/Los_Angeles"
        VIRTUAL_HOST  = "pihole.${var.domain}"
        WEB_PORT      = "${NOMAD_PORT_http}"
      }

      template {
        destination = "secrets/pihole.env"
        env         = true
        change_mode = "noop"
        data        = <<EOF
WEBPASSWORD="{{with secret "nomad/data/pihole"}}{{.Data.data.WEBPASSWORD}}{{end}}"
EOF
      }

      resources {
        cpu    = 1380
        memory = 78
      }

      template {
        destination = "local/etc-dnsmasq.d/00-custom.conf"
        change_mode = "restart"
        data        = <<EOF
# Enable forward lookup of the 'consul' domain:
{{range service "consul"}}server=/consul/{{.Address}}#8600
{{end}}
# Uncomment and modify as appropriate to enable reverse DNS lookups for
# common netblocks found in RFC 1918, 5735, and 6598:
#rev-server=0.0.0.0/8,127.0.0.1#8600
#rev-server=10.0.0.0/8,127.0.0.1#8600
#rev-server=100.64.0.0/10,127.0.0.1#8600
#rev-server=127.0.0.1/8,127.0.0.1#8600
#rev-server=169.254.0.0/16,127.0.0.1#8600
#rev-server=172.16.0.0/12,127.0.0.1#8600
rev-server=192.168.0.0/16,127.0.0.1#8600
#rev-server=224.0.0.0/4,127.0.0.1#8600
#rev-server=240.0.0.0/4,127.0.0.1#8600

# Local records
address=/pihole.${var.domain}/{{range service "traefik-websecure"}}{{.Address}}{{end}}
address=/traefik.${var.domain}/{{range service "traefik-websecure"}}{{.Address}}{{end}}
address=/vault.${var.domain}/{{range service "active.vault"}}{{.Address}}{{end}}
{{range $tag, $services := services | byTag}}{{ if eq $tag "dnsmasq.cname=true" }}{{range $services}}address=/{{.Name}}.${var.domain}/{{range service "traefik-websecure"}}{{.Address}}{{end}}
{{end}}{{end}}{{end}}
EOF
      }

      template {
        destination = "local/pihole/pihole-FTL.conf"
        change_mode = "noop"
        data        = <<EOF
PRIVACYLEVEL=0
EOF
      }

      service {
        name = "pihole"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pihole.entryPoints=websecure",
          "traefik.http.routers.pihole.rule=Host(`pihole.${var.domain}`)",
          "traefik.http.routers.pihole.tls=true",
        ]

        check {
          type     = "http"
          path     = "/admin/"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      service {
        name = "dns"
        port = "dns"

        check {
          name     = "service: dns tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"
        }

        check {
          name     = "service: dns dig check"
          type     = "script"
          command  = "/usr/bin/dig"
          args     = ["+short", "@127.0.0.1"]
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      scaling "cpu" {
        enabled = true
        max     = 2000

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        max     = 1024

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "keepalived" {
      driver = "docker"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      env {
        KEEPALIVED_INTERFACE     = "ens160"
        KEEPALIVED_ROUTER_ID     = "53"
        KEEPALIVED_STATE         = "MASTER"
        KEEPALIVED_UNICAST_PEERS = ""
        KEEPALIVED_VIRTUAL_IPS   = "${var.subnet_cidr}.253"
      }

      config {
        image        = "osixia/keepalived:2.0.20"
        network_mode = "host"
        cap_add = [
          "NET_ADMIN",
          "NET_BROADCAST",
          "NET_RAW"
        ]
      }

      resources {
        cpu    = 20
        memory = 10
      }
    }

    task "cloudflared" {
      driver = "exec"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        command = "/tmp/cloudflared/cloudflared-linux-amd64"

        args = [
          "proxy-dns",
          "--address",
          "0.0.0.0",
          "--port",
          "${NOMAD_PORT_cloudflared}",
          "--metrics",
          "0.0.0.0:${NOMAD_PORT_prometheus_cloudflared_metrics}",
          "--upstream",
          "https://1.1.1.2/dns-query",
          "--upstream",
          "https://1.0.0.2/dns-query",
        ]
      }

      artifact {
        source      = "https://github.com/cloudflare/cloudflared/releases/download/2022.3.1/cloudflared-linux-amd64"
        destination = "/tmp/cloudflared"

        options {
          checksum = "sha256:42b3b77560792d4c1e2f1d1caf2249e52acd48da65a8837d8d1a2849b384e58c"
        }
      }

      resources {
        cpu    = 57
        memory = 23
      }

      service {
        name = "cloudflared"
        port = "cloudflared"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      service {
        name = "prometheus-cloudflared-metrics"
        port = "prometheus_cloudflared_metrics"

        check {
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      scaling "cpu" {
        enabled = true
        max     = 500

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

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
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "prometheus-pihole-exporter" {
      driver = "docker"

      restart {
        attempts = 30
        interval = "5m"
        delay    = "15s"
        mode     = "fail"
      }

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      config {
        image = "ekofr/pihole-exporter:v0.3.0"
        ports = ["prometheus_pihole_exporter"]
      }

      env {
        INTERVAL        = "30s"
        PIHOLE_HOSTNAME = "${NOMAD_IP_http}"
        PIHOLE_PORT     = "${NOMAD_PORT_http}"
        PORT            = "${NOMAD_PORT_prometheus_pihole_exporter}"
      }

      resources {
        cpu    = 57
        memory = 12 # repeat oom killed at 11
      }

      scaling "cpu" {
        enabled = true
        max     = 500

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

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
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      template {
        destination = "secrets/pihole.env"
        env         = true
        change_mode = "noop"
        data        = <<EOF
  PIHOLE_API_TOKEN="{{with secret "nomad/data/pihole"}}{{.Data.data.WEBPASSWORD}}{{end}}"
  EOF
      }

      service {
        name = "prometheus-pihole-exporter"
        port = "prometheus_pihole_exporter"

        check {
          type     = "http"
          path     = "/metrics"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }
    }
  }
}

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
        image        = "pihole/pihole:2021.09"
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
        VIRTUAL_HOST  = "pihole.hashidemos.io"
        WEB_PORT      = "${NOMAD_PORT_http}"
      }

      template {
        destination = "secrets/pihole.env"
        env         = true

        data = <<EOF
WEBPASSWORD="{{with secret "nomad/data/pihole"}}{{.Data.data.WEBPASSWORD}}{{end}}"
EOF
      }

      resources {
        cpu    = 1494
        memory = 125
      }

      template {
        destination = "local/etc-dnsmasq.d/00-custom.conf"
        change_mode = "restart"
        data        = <<EOF
# Enable forward lookup of the 'consul' domain:
{{range service "consul"}}server=/consul/{{.Address}}#8600
{{end}}
# Local records
cname=traefik.hashidemos.io,traefik.service.consul
cname=pihole.hashidemos.io,traefik.service.consul
{{range $tag, $services := services | byTag}}{{ if eq $tag "dnsmasq.cname=true" }}{{range $services}}cname={{.Name}}.hashidemos.io,traefik.service.consul
{{end}}{{end}}{{end}}
EOF
      }

      template {
        destination = "local/pihole/pihole-FTL.conf"

        data = <<EOF
PRIVACYLEVEL=0
EOF
      }

      template {
        destination = "local/consul-udp-check"
        perms       = "755"

        data = <<EOF
#!/bin/bash

set -uo pipefail

nc -zuv $1 $2

# Exit code 1 from netcat denotes a failure in network connectivity. We wrap this and send an exit code above 1, 
# say 2, because, consul's script check considers exit code 1 as a WARNING and exit code 0 as a SUCCESS and anything
# other than that is considered a FAILURE.
if [[ "$?" != "0" ]]; then
 exit 2
fi
EOF
      }

      service {
        name = "pihole"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pihole.entryPoints=websecure",
          "traefik.http.routers.pihole.rule=Host(`pihole.hashidemos.io`)",
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

        // check {
        //   name     = "service: dns udp check"
        //   type     = "script"
        //   command  = "/local/consul-udp-check"
        //   args     = ["localhost", "${NOMAD_PORT_dns}"]
        //   interval = "10s"
        //   timeout  = "2s"
        // }

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
          cooldown            = "24h"
          evaluation_interval = "24h"

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
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "keepalived" {
      driver = "docker"

      env {
        KEEPALIVED_INTERFACE     = "ens160"
        KEEPALIVED_ROUTER_ID     = "53"
        KEEPALIVED_STATE         = "MASTER"
        KEEPALIVED_UNICAST_PEERS = ""
        KEEPALIVED_VIRTUAL_IPS   = "192.168.0.253"
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
        cpu    = 57
        memory = 20
      }

      scaling "cpu" {
        enabled = true
        max     = 500

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        min     = 20 # less than this will fail to start
        max     = 512

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "cloudflared" {
      driver = "exec"

      config {
        command = "/tmp/cloudflared/cloudflared"

        args = [
          "proxy-dns",
          "--address",
          "0.0.0.0",
          "--port",
          "${NOMAD_PORT_cloudflared}",
          "--metrics",
          "0.0.0.0:${NOMAD_PORT_prometheus_cloudflared_metrics}",
          "--upstream",
          "https://1.1.1.1/dns-query",
          "--upstream",
          "https://1.0.0.1/dns-query",
        ]
      }

      artifact {
        source      = "https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz"
        destination = "/tmp/cloudflared"
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
          cooldown            = "24h"
          evaluation_interval = "24h"

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
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "prometheus-pihole-exporter" {
      driver = "docker"

      config {
        image = "ekofr/pihole-exporter:v0.0.11"
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
        memory = 11
      }

      scaling "cpu" {
        enabled = true
        max     = 500

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

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
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      template {
        destination = "secrets/pihole.env"
        env         = true

        data = <<EOF
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
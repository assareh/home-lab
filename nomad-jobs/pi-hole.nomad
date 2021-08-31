job "pihole" {
  datacenters = ["dc1"]

  group "pihole" {
    count = 2

    vault {
      policies = ["pihole"]
    }

    update {
      auto_revert  = true
      auto_promote = true
      canary       = 1
      stagger      = "60s"
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "cloudflared" {}

      port "metrics" {}

      port "http" {
        to = 80
      }

      port "dns" {
        to = 53
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
          "127.0.0.1:${NOMAD_PORT_metrics}",
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
        memory = 128
      }

      service {
        name = "cloudflared"
        port = "cloudflared"

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"

          check_restart {
            limit           = 3
            grace           = "90s"
            ignore_warnings = false
          }
        }
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 500

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        min     = 128
        max     = 512

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    task "pihole" {
      driver = "docker"

      config {
        image       = "pihole/pihole:v5.8.1"
        ports       = ["http", "dns"]
        dns_servers = ["127.0.0.1", "1.1.1.1"]

        volumes = [
          "local/etc-dnsmasq.d/00-custom.conf:/etc/dnsmasq.d/00-custom.conf",
          "local/pihole/pihole-FTL.conf:/etc/pihole/pihole-FTL.conf",
        ]
      }

      env {
        TZ            = "America/Los_Angeles"
        DNSSEC        = "true"
        VIRTUAL_HOST  = "pihole.hashidemos.io"
        ServerIP      = "${attr.unique.network.ip-address}"
        QUERY_LOGGING = "false"
        PIHOLE_DNS_   = "${attr.unique.network.ip-address}#${NOMAD_PORT_cloudflared};${attr.unique.network.ip-address}#53"
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
        memory = 128
      }

      template {
        destination = "local/etc-dnsmasq.d/00-custom.conf"
        change_mode = "restart"
        data        = <<EOF
# Enable forward lookup of the 'consul' domain:
{{range service "consul"}}
server=/consul/{{.Address}}#8600{{end}}

# Local records
# the next line is temporary and will be removed soon once esxi has service registration
address=/esxi.hashidemos.io/192.168.10.6
#
cname=traefik.hashidemos.io,traefik.service.consul
cname=pihole.hashidemos.io,traefik.service.consul
{{range $tag, $services := services | byTag}}{{ if eq $tag "dnsmasq.cname=true" }}{{range $services}}
cname={{.Name}}.hashidemos.io,traefik.service.consul{{end}}{{end}}{{end}}
EOF
      }

      template {
        destination = "local/pihole/pihole-FTL.conf"

        data = <<EOF
PRIVACYLEVEL=3
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
        }
      }

      service {
        name = "dns"
        port = "dns"

        check {
          name     = "service: dns udp check"
          type     = "script"
          command  = "/local/consul-udp-check"
          args     = ["localhost", "53"]
          interval = "15s"
          timeout  = "5s"
        }

        check {
          name     = "service: dns tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }

        check {
          name     = "service: dns dig check"
          type     = "script"
          command  = "/usr/bin/dig"
          args     = ["@127.0.0.1", "cloudflare.com"]
          interval = "30s"
          timeout  = "5s"
        }
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 2000

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        enabled = true
        min     = 128
        max     = 1024

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }
  }
}

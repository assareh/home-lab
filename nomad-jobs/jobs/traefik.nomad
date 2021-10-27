job "traefik" {
  datacenters = ["dc1"]

  priority = 85

  group "traefik" {
    shutdown_delay = "5s"

    vault {
      policies = ["consul-client-tls", "traefik"]
    }

    volume "traefik" {
      type            = "csi"
      source          = "traefik"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    restart {
      attempts = 2
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    update {
      auto_revert  = true
      auto_promote = true
      canary       = 1
      stagger      = "60s"
    }

    network { # should put any ports that are entrypoints below here
      port "https" {
        static = 443
      }

      port "http" {
        static = 80
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik-dashboard"
      port = "api"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.traefik.entryPoints=websecure",
        "traefik.http.routers.traefik.rule=Host(`traefik.hashidemos.io`)",
        "traefik.http.routers.traefik.tls=true",
        "traefik.http.routers.traefik.tls.certresolver=letsencrypt",
        "traefik.http.routers.traefik.tls.domains[0].main=*.hashidemos.io",
        "traefik.http.routers.traefik.tls.domains[0].sans=hashidemos.io",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "api"
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
      name = "traefik-http"
      port = "http"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
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
      name = "traefik"
      port = "https"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "https"
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

    task "keepalived" {
      driver = "docker"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      env {
        KEEPALIVED_INTERFACE     = "ens160"
        KEEPALIVED_ROUTER_ID     = "52"
        KEEPALIVED_STATE         = "BACKUP"
        KEEPALIVED_UNICAST_PEERS = ""
        KEEPALIVED_VIRTUAL_IPS   = "192.168.0.200"
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
        memory = 10
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

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.5.0"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      volume_mount {
        volume      = "traefik"
        destination = "/opt/traefik"
      }

      env {
        GCE_PROJECT              = "hashidemos-io-dns"
        GCE_SERVICE_ACCOUNT_FILE = "secrets/gce-service-account.json"
        TZ                       = "US/Los_Angeles"
      }

      template {
        data = <<EOF
[accessLog]
  filePath = "/opt/traefik/access-{{ env "attr.unique.network.ip-address" }}.log"
  
[api]
  dashboard = true
  insecure  = true

[certificatesResolvers.letsencrypt.acme]
  email = "andy@hashidemos.io"
  storage = "/opt/traefik/acme.json"
  # use staging server for testing
  # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
  [certificatesResolvers.letsencrypt.acme.dnsChallenge]
    provider = "gcloud"
    resolvers = ["1.1.1.1:53", "8.8.8.8:53"]

[entryPoints]
[entryPoints.web]
  address = ":{{env "NOMAD_PORT_http"}}"

  [entryPoints.web.http]
    [entryPoints.web.http.redirections]
      [entryPoints.web.http.redirections.entryPoint]
        to = "websecure"
        scheme = "https"

[entryPoints.websecure]
  address = ":{{env "NOMAD_PORT_https"}}"

  [entryPoints.websecure.http.tls]
    certResolver = "letsencrypt"

[entryPoints.traefik]
  address = ":{{env "NOMAD_PORT_api"}}"

# [entryPoints.vmrc902t]
#   address = ":902/tcp"

# [entryPoints.vmrc902u]
#   address = ":902/udp"

# [entryPoints.vmrc903t]
#   address = ":903/tcp"

[log]
  filePath = "/opt/traefik/traefik-{{ env "attr.unique.network.ip-address" }}.log"
  
[pilot]
  token = "${pilot_token}"

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    connectAware     = true
    exposedByDefault = false
    prefix           = "traefik"

    [providers.consulCatalog.endpoint]
      address = "localhost:8501"
      scheme  = "https"

      [providers.consulCatalog.endpoint.tls]
      ca      = "secrets/ca.pem"
      cert    = "secrets/cert.pem"
      key     = "secrets/key.pem"

[serversTransport]
# finish rolling out Connect or add my CA to disable this
  insecureSkipVerify = true

EOF

        destination = "local/traefik.toml"
      }

      template {
        destination = "secrets/gce-service-account.json"
        perms       = "400"
        data        = <<EOF
{{with secret "nomad/data/gcloud"}}{{.Data.data.GCE_SERVICE_ACCOUNT}}{{end}}
EOF
      }

      template {
        destination = "secrets/ca.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=traefik.client.dc1.consul" }}
{{ .Data.issuing_ca }}{{ end }}
EOF
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=traefik.client.dc1.consul" }}
{{ .Data.certificate }}{{ end }}
EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=traefik.client.dc1.consul" }}
{{ .Data.private_key }}{{ end }}
EOF
      }

      resources {
        cpu    = 57
        memory = 52
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
  }
}

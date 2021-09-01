job "traefik" {
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {
    vault {
      policies = ["gcloud"]
    }

    update {
      auto_revert  = true
      auto_promote = true
      canary       = 1
      stagger      = "60s"
    }

    network {
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
      }
    }

    task "keepalived" {
      driver = "docker"

      env {
        KEEPALIVED_INTERFACE     = "ens160"
        KEEPALIVED_VIRTUAL_IPS   = "192.168.0.200"
        KEEPALIVED_STATE         = "BACKUP"
        KEEPALIVED_UNICAST_PEERS = ""
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
        cpu    = 100
        memory = 128
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

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.5.0-rc5"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "/mnt/data/traefik:/opt/traefik",
        ]
      }

      env {
        GCE_PROJECT              = ""
        GCE_SERVICE_ACCOUNT_FILE = "secrets/gce-service-account.json"
        TZ                       = "US/Los_Angeles"
      }

      template {
        data = <<EOF
[accessLog]
  filePath = "/opt/traefik/access.log"

[api]
  dashboard = true
  insecure  = true

[certificatesResolvers.letsencrypt.acme]
  email = ""
  storage = "/opt/traefik/acme.json"
  # use staging server for testing
  # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
  [certificatesResolvers.letsencrypt.acme.dnsChallenge]
    provider = "gcloud"
    resolvers = ["1.1.1.1:53", "8.8.8.8:53"]

[entryPoints]
[entryPoints.web]
  address = ":80"

  [entryPoints.web.http]
    [entryPoints.web.http.redirections]
      [entryPoints.web.http.redirections.entryPoint]
        to = "websecure"
        scheme = "https"

[entryPoints.websecure]
  address = ":443"

  [entryPoints.websecure.http.tls]
    certResolver = "letsencrypt"

[entryPoints.traefik]
  address = ":8081"

[entryPoints.vmrc]
  address = ":902"

[log]
  filePath = "/opt/traefik/traefik.log"

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    connectAware     = true
    exposedByDefault = false
    prefix           = "traefik"

    [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"

[serversTransport]
# finish rolling out Connect or add my CA to disable this
  insecureSkipVerify = true

EOF

        destination = "local/traefik.toml"
      }

      template {
        destination = "secrets/gce-service-account.json"
        perms       = "755"
        data        = <<EOF
{{with secret "nomad/data/gcloud"}}{{.Data.data.GCE_SERVICE_ACCOUNT}}{{end}}
EOF
      }

      resources {
        cpu    = 100
        memory = 128
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
  }
}

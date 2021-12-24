variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "email" {
  type    = string
  default = "andy@hashidemos.io"
}

variable "google_project" {
  type    = string
  default = "hashidemos-io-dns"
}

variable "subnet_cidr" {
  type    = string
  default = "192.168.0"
}

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
      port "websecure" {
        static = 443
      }

      port "web" {
        static = 80
      }

      port "traefik" {}
    }

    service {
      name = "traefik"
      port = "traefik"

      tags = [
        "traefik.enable=true",

        "traefik.http.routers.traefik.tls.certresolver=letsencrypt",
        "traefik.http.routers.traefik.tls.domains[0].main=*.${var.domain}",

        "traefik.http.routers.traefik.entryPoints=websecure",
        "traefik.http.routers.traefik.tls=true",
        "traefik.http.routers.traefik.service=api@internal",
        "traefik.http.routers.traefik.rule=Host(`traefik.${var.domain}`) && PathPrefix(`/api`, `/dashboard`)",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "traefik"
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
      name = "traefik-web"
      port = "web"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "web"
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
      name = "traefik-websecure"
      port = "websecure"

      check {
        name            = "traefik: consul provider ready"
        type            = "http"
        protocol        = "https"
        port            = "websecure"
        path            = "/api/http/services/traefik@consulcatalog"
        interval        = "30s"
        timeout         = "5s"
        tls_skip_verify = true

        header {
          Host = ["traefik.${var.domain}"]
        }

        success_before_passing   = "3"
        failures_before_critical = "3"

        check_restart {
          limit = 3
          grace = "180s"
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
        KEEPALIVED_VIRTUAL_IPS   = "${var.subnet_cidr}.200"
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

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.5.4"
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
        GCE_PROJECT              = "${var.google_project}"
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
  email = "andy@${var.email}"
  storage = "/opt/traefik/acme.json"
  # use staging server for testing
  # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
  [certificatesResolvers.letsencrypt.acme.dnsChallenge]
    provider = "gcloud"
    resolvers = ["1.1.1.1:53", "8.8.8.8:53"]

[entryPoints]
[entryPoints.web]
  address = ":{{env "NOMAD_PORT_web"}}"

  [entryPoints.web.http]
    [entryPoints.web.http.redirections]
      [entryPoints.web.http.redirections.entryPoint]
        to = "websecure"
        scheme = "https"

[entryPoints.websecure]
  address = ":{{env "NOMAD_PORT_websecure"}}"

  [entryPoints.websecure.http.tls]
    certResolver = "letsencrypt"

[entryPoints.traefik]
  address = ":{{env "NOMAD_PORT_traefik"}}"

# [entryPoints.vmrc902t]
#   address = ":902/tcp"

# [entryPoints.vmrc902u]
#   address = ":902/udp"

# [entryPoints.vmrc903t]
#   address = ":903/tcp"

[log]
  filePath = "/opt/traefik/traefik-{{ env "attr.unique.network.ip-address" }}.log"
  # level    = "DEBUG"

# ping

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
        cpu    = 20
        memory = 52
      }
    }
  }
}

job "homebridge" {
  datacenters = ["dc1"]

  group "homebridge" {
    volume "homebridge" {
      type            = "csi"
      source          = "homebridge"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    vault {
      policies = ["homebridge"]
    }

    network {
      port "http" {
        static = 8581
      }
    }

    service {
      name = "homebridge"
      port = "http"

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.http.routers.homebridge.entryPoints=websecure",
        "traefik.http.routers.homebridge.rule=Host(`homebridge.hashidemos.io`)",
        "traefik.http.routers.homebridge.tls=true",
      ]

      check {
        type     = "http"
        port     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"

        check_restart {
          limit = 3
          grace = "240s"
        }
      }
    }

    task "homebridge" {
      driver = "docker"

      volume_mount {
        volume      = "homebridge"
        destination = "/homebridge"
      }

      config {
        image        = "oznu/homebridge:4.0.0"
        network_mode = "host"

        volumes = [
          "local/config.json:/homebridge/config.json",
        ]
      }

      env {
        HOMEBRIDGE_CONFIG_UI      = "1"
        HOMEBRIDGE_CONFIG_UI_PORT = "${NOMAD_PORT_http}"
        TZ                        = "America/Los_Angeles"
        VAULT_ADDR                = "https://vault.service.consul:8200"
      }

      template {
        destination = "secrets/hue.env"
        env         = true

        data = <<EOF
HUE_API_KEY="{{with secret "nomad/data/homebridge"}}{{.Data.data.HUE_API_KEY}}{{end}}"
EOF
      }

      template {
        data = <<EOF
{
    "mdns": {
        "interface": "{{ env "attr.unique.network.ip-address" }}"
    },
    "bridge": {
        "name": "Homebridge",
        "username": "{{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_USERNAME}}{{end}}",
        "port": "{{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_PORT}}{{end}}",
        "pin": "{{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_PIN}}{{end}}"
    },
    "accessories": [
    ],
  "platforms": [
    {
      "platform": "config",
      "name": "Config",
      "port": {{ env "NOMAD_HOST_PORT_http" }}
    }
  ]
}
EOF

        destination = "local/config.json"
      }

      resources {
        cpu    = 500
        memory = 256
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
  }
}

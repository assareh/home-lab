job "homebridge" {
  datacenters = ["dc1"]

  group "homebridge" {

    vault {
      policies = ["homebridge"]
    }

    network {
      port "http" {
        static = 8581
        to     = 8581
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
        interval = "15s"
        timeout  = "2s"
      }
    }

    task "homebridge" {
      driver = "docker"

      config {
        image        = "oznu/homebridge:4.0.0"
        network_mode = "host"

        volumes = [
          "/mnt/data/homebridge:/homebridge",
          "local/config.json:/homebridge/config.json",
        ]
      }

      env {
        HOMEBRIDGE_CONFIG_UI      = "1"
        HOMEBRIDGE_CONFIG_UI_PORT = "8581"
        TZ                        = "America/Los_Angeles"
        VAULT_ADDR                = "https://vault.service.consul:8200"
      }

      template {
        destination = "secrets/hue.env"
        env         = true

        data = <<EOF
HUE_API_KEY="{{with secret "hue/data/api-key"}}{{.Data.data.HUE_API_KEY}}{{end}}"
EOF
      }

      template {
        data = <<EOF
{
    "mdns": {
        "interface": "{{ env "attr.unique.network.ip-address" }}"
    },
    "bridge": {
    },
    "accessories": [
    ],
  "platforms": [
    {
      "platform": "SmartThings-v2",
      "name": "SmartThings-v2",
      "app_url": "https://graph-na04-useast2.api.smartthings.com:443/api/smartapps/installations/",
      "app_id": "{{with secret "nomad/data/smartthings"}}{{.Data.data.app_id}}{{end}}",
      "access_token": "{{with secret "nomad/data/smartthings"}}{{.Data.data.access_token}}{{end}}",
      "temperature_unit": "F",
      "validateTokenId": false,
      "logConfig": {
        "debug": false,
        "showChanges": true,
        "hideTimestamp": false,
        "hideNamePrefix": false,
        "file": {
          "enabled": true
        }
      }
    },
    {
      "platform": "config",
      "name": "Config",
      "port": 8581
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

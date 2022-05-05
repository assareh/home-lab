variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

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
      policies = ["homebridge", "pki"]
    }

    network {
      port "https" {}
    }

    service {
      name = "homebridge"
      port = "https"

      tags = [
        "dnsmasq.cname=true",
        "traefik.enable=true",
        "traefik.http.routers.homebridge.entryPoints=websecure",
        "traefik.http.routers.homebridge.rule=Host(`homebridge.${var.domain}`)",
        "traefik.http.routers.homebridge.tls=true",
        "traefik.http.services.homebridge.loadbalancer.server.scheme=https"
      ]

      check {
        name     = "service: homebridge tcp check"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"

        check_restart {
          limit = 3
          grace = "180s"
        }
      }

      check {
        name     = "service: homebridge readiness check"
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
        protocol = "https"

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

      artifact {
        source      = "git::https://github.com/assareh/homebridge.git"
        destination = "local/scripts/"
      }

      config {
        image        = "docker-registry.service.consul:5000/homebridge:latest" # using custom image with python requests and hvac
        network_mode = "host"
        volumes = [
          "local/config.json:/homebridge/config.json",
          "local/scripts/:/homebridge/scripts/",
        ]
      }

      env {
        HOMEBRIDGE_CONFIG_UI      = "1"
        HOMEBRIDGE_CONFIG_UI_PORT = "${NOMAD_PORT_https}"
        HUE_API_URL               = "https://hue-api.service.consul/api/"
        TZ                        = "America/Los_Angeles"
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
      "bridge": 
        {
          "name": "Homebridge",
          "bind": "{{ env "attr.unique.network.ip-address" }}",
          "username": "{{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_USERNAME}}{{end}}",
          "port": {{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_PORT}}{{end}},
          "pin": "{{with secret "nomad/data/homebridge"}}{{.Data.data.BRIDGE_PIN}}{{end}}"
        },
      "accessories": [
        {
            "accessory": "Script2",
            "name": "Color Cycle Leo's Lamp",
            "on": "/homebridge/scripts/crossfade_on_leo.sh",
            "off": "/homebridge/scripts/crossfade_off_leo.sh",
            "state": "/homebridge/scripts/crossfade_state_leo.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Color Cycle Living Room Lamp",
            "on": "/homebridge/scripts/crossfade_on_lr.sh",
            "off": "/homebridge/scripts/crossfade_off_lr.sh",
            "state": "/homebridge/scripts/crossfade_state_lr.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Color Cycle Office Lamp",
            "on": "/homebridge/scripts/crossfade_on_office.sh",
            "off": "/homebridge/scripts/crossfade_off_office.sh",
            "state": "/homebridge/scripts/crossfade_state_office.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp terraform",
            "on": "/homebridge/scripts/office_terraform_on.sh",
            "off": "/homebridge/scripts/office_terraform_off.sh",
            "state": "/homebridge/scripts/office_terraform_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp vault",
            "on": "/homebridge/scripts/office_vault_on.sh",
            "off": "/homebridge/scripts/office_vault_off.sh",
            "state": "/homebridge/scripts/office_vault_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp consul",
            "on": "/homebridge/scripts/office_consul_on.sh",
            "off": "/homebridge/scripts/office_consul_off.sh",
            "state": "/homebridge/scripts/office_consul_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp nomad",
            "on": "/homebridge/scripts/office_nomad_on.sh",
            "off": "/homebridge/scripts/office_nomad_off.sh",
            "state": "/homebridge/scripts/office_nomad_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp boundary",
            "on": "/homebridge/scripts/office_boundary_on.sh",
            "off": "/homebridge/scripts/office_boundary_off.sh",
            "state": "/homebridge/scripts/office_boundary_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp waypoint",
            "on": "/homebridge/scripts/office_waypoint_on.sh",
            "off": "/homebridge/scripts/office_waypoint_off.sh",
            "state": "/homebridge/scripts/office_waypoint_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp vagrant",
            "on": "/homebridge/scripts/office_vagrant_on.sh",
            "off": "/homebridge/scripts/office_vagrant_off.sh",
            "state": "/homebridge/scripts/office_vagrant_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Office Lamp packer",
            "on": "/homebridge/scripts/office_packer_on.sh",
            "off": "/homebridge/scripts/office_packer_off.sh",
            "state": "/homebridge/scripts/office_packer_state.sh",
            "on_value": "true"
        },
        {
            "accessory": "Script2",
            "name": "Fade Leo's Lamp",
            "on": "/homebridge/scripts/bedtime_on.sh",
            "off": "/homebridge/scripts/bedtime_off.sh",
            "state": "/homebridge/scripts/bedtime_state.sh",
            "on_value": "true"
        }
    ],
  "platforms": [
    {
      "platform": "config",
      "name": "Config",
      "port": {{ env "NOMAD_HOST_PORT_https" }},
      "ssl": {
        "key": "/secrets/key.pem",
        "cert": "/secrets/cert.pem"
        }
    }
  ]
}
EOF

        destination = "local/config.json"
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "640"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=homebridge.service.consul" $ip_sans }}
{{ .Data.certificate }}{{ end }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=homebridge.service.consul" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "440"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=homebridge.service.consul" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      resources {
        cpu    = 57
        memory = 239
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
  }
}

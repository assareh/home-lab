variable "domain" {
  type    = string
  default = "hashidemos.io"
}

job "splunk" {
  datacenters = ["dc1"]

  group "splunk" {
    vault {
      policies = ["splunk"]
    }

    network {
      port "http" {
        to = 8000
      }

      port "http_event_collector" {
        static = 8088
      }

      port "syslog" {
        static = 514
      }
    }

    volume "splunk_etc" {
      type            = "csi"
      source          = "splunk_etc"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "splunk_var" {
      type            = "csi"
      source          = "splunk_var"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "splunk" {
      driver         = "docker"
      shutdown_delay = "5s"

      config {
        image = "splunk/splunk:8.1.3-debian"
        ports = ["http", "http_event_collector", "syslog"]
      }

      volume_mount {
        volume      = "splunk_etc"
        destination = "/opt/splunk/etc"
      }

      volume_mount {
        volume      = "splunk_var"
        destination = "/opt/splunk/var"
      }

      env {
        SPLUNK_START_ARGS  = "--accept-license"
        SPLUNK_LICENSE_URI = "Free"
      }

      template {
        destination = "secrets/splunk.env"
        env         = true

        data = <<EOF
SPLUNK_PASSWORD="{{with secret "nomad/data/splunk"}}{{.Data.data.SPLUNK_PASSWORD}}{{end}}"
EOF
      }

      service {
        name = "splunk"
        port = "http"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.splunk.entryPoints=websecure",
          "traefik.http.routers.splunk.rule=Host(`splunk.${var.domain}`)",
          "traefik.http.routers.splunk.tls=true",
        ]

        check {
          type     = "http"
          path     = "/"
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
        name = "splunk-http-event-collector"
        port = "http_event_collector"

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
        name = "splunk-syslog"
        port = "syslog"
        ## can not do UDP check because nc not installed in splunk image
      }

      resources {
        cpu    = 250
        memory = 1024
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

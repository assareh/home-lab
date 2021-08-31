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

      port "collector" {
        static = 9090
        to     = 9090
      }

      port "syslog" {
        static = 8514
        to     = 8514
      }
    }

    task "splunk" {
      driver = "docker"

      config {
        image = "splunk/splunk:8.1.3-debian"
        ports = ["http", "collector", "syslog"]

        volumes = [
          "/mnt/data/splunk/etc:/opt/splunk/etc",
          "/mnt/data/splunk/var:/opt/splunk/var",
        ]
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
          "traefik.http.routers.splunk.rule=Host(`splunk.hashidemos.io`)",
          "traefik.http.routers.splunk.tls=true",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "splunk-collector"
        port = "collector"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "splunk-syslog"
        port = "syslog"
        ## can not do UDP check because nc not installed in splunk image
      }

      resources {
        cpu    = 517
        memory = 1024
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

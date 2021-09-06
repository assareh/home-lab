job "unifi" {
  datacenters = ["dc1"]

  group "unifi" {
    volume "unifi" {
      type            = "csi"
      source          = "unifi"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    network {
      port "cmdctrl" {
        static = 8080
        to     = 8080
      }

      port "https" {
        to = 8443
      }

      port "stun" {
        static = 3478
        to     = 3478
      }
    }

    task "keepalived" {
      driver = "docker"

      env {
        KEEPALIVED_INTERFACE     = "ens160"
        KEEPALIVED_VIRTUAL_IPS   = "192.168.0.250"
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

    task "unifi" {
      driver = "docker"

      volume_mount {
        volume      = "unifi"
        destination = "/unifi/data"
        read_only   = false
      }

      volume_mount {
        volume      = "unifi"
        destination = "/unifi/log"
        read_only   = false
      }

      config {
        image = "jacobalberty/unifi:v6.2.26"
        ports = ["cmdctrl", "https", "stun"]
      }

      env {
        TZ = "America/Los_Angeles"
      }

      service {
        name = "unifi-cmdctrl"
        port = "cmdctrl"

        # add check
      }

      service {
        name = "unifi-stun"
        port = "stun"

        # add check
      }

      service {
        name = "unifi"
        port = "https"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.unifi.entryPoints=websecure",
          "traefik.http.routers.unifi.rule=Host(`unifi.hashidemos.io`)",
          "traefik.http.routers.unifi.tls=true",
          "traefik.http.services.unifi.loadbalancer.server.scheme=https",
        ]

        check {
          type     = "http"
          port     = "https"
          protocol = "https"
          path     = "/status"
          interval = "30s"
          timeout  = "2s"

          tls_skip_verify = true
        }
      }

      resources {
        cpu    = 500
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
        max     = 2048

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

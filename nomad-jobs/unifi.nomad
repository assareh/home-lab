job "unifi" {
  datacenters = ["dc1"]

  group "unifi" {
    vault {
      policies = ["pki"]
    }

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
        volumes = [
          "secrets/certs:/unifi/cert",
        ]
      }

      env {
        TZ = "America/Los_Angeles"
      }

      service {
        name = "unifi-cmdctrl"
        port = "cmdctrl"

        check {
          name     = "service: cmdctrl tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      service {
        name = "unifi-stun"
        port = "stun"
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

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      template {
        destination = "secrets/certs/cert.pem"
        perms       = "640"
        data        = <<-EOF
          {{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=unifi.service.consul" "alt_names=unifi.hashidemos.io" $ip_sans }}
          {{ .Data.certificate }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/privkey.pem"
        perms       = "400"
        data        = <<-EOF
          {{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=unifi.service.consul" "alt_names=unifi.hashidemos.io" $ip_sans }}
          {{ .Data.private_key }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/chain.pem"
        perms       = "640"
        data        = <<-EOF
          {{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=unifi.service.consul" "alt_names=unifi.hashidemos.io" $ip_sans }}
          {{ .Data.issuing_ca }}{{ end }}
          EOF
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

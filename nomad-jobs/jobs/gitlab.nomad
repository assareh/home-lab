job "gitlab" {
  datacenters = ["dc1"]

  group "gitlab" {
    vault {
      policies = ["pki"]
    }

    network {
      port "https" {
        to = 443
      }
    }

    volume "gitlab_config" {
      type            = "csi"
      source          = "gitlab_config"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "gitlab_data" {
      type            = "csi"
      source          = "gitlab_data"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "gitlab_logs" {
      type            = "csi"
      source          = "gitlab_logs"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "gitlab" {
      driver         = "docker"
      kill_timeout   = "45s"
      shutdown_delay = "5s"

      config {
        image = "gitlab/gitlab-ee:13.11.1-ee.0"
        ports = ["https"]
        volumes = [
          "secrets/certs:/etc/gitlab/ssl",
        ]
      }

      volume_mount {
        volume      = "gitlab_config"
        destination = "/etc/gitlab"
      }

      volume_mount {
        volume      = "gitlab_data"
        destination = "/var/opt/gitlab"
      }

      volume_mount {
        volume      = "gitlab_logs"
        destination = "/var/log/gitlab"
      }

      service {
        name = "gitlab"
        port = "https"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.gitlab.entryPoints=websecure",
          "traefik.http.routers.gitlab.rule=Host(`gitlab.hashidemos.io`)",
          "traefik.http.routers.gitlab.tls=true",
          "traefik.http.services.gitlab.loadbalancer.server.scheme=https",
        ]

        check {
          name     = "service: gitlab tcp check"
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
          name     = "service: gitlab readiness check"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/-/readiness?token="
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "180s"
          }
        }

        check {
          name     = "service: gitlab liveness check"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/-/liveness?token="
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "180s"
          }
        }
      }

      template {
        destination = "secrets/certs/gitlab.hashidemos.io.crt"
        perms       = "640"
        data        = <<-EOF
          {{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=gitlab.service.consul" "alt_names=gitlab.hashidemos.io" $ip_sans }}
          {{ .Data.certificate }}{{ end }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=gitlab.service.consul" "alt_names=gitlab.hashidemos.io" $ip_sans }}
          {{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/gitlab.hashidemos.io.key"
        perms       = "400"
        data        = <<-EOF
          {{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
          {{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=gitlab.service.consul" "alt_names=gitlab.hashidemos.io" $ip_sans }}
          {{ .Data.private_key }}{{ end }}
          EOF
      }

      resources {
        cpu    = 1494
        memory = 4096
      }

      scaling "cpu" {
        enabled = true
        max     = 4000

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
        max     = 4096

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

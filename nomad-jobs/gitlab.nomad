job "gitlab" {
  datacenters = ["dc1"]

  group "gitlab" {
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
      driver       = "docker"
      kill_timeout = "45s"

      config {
        image = "gitlab/gitlab-ee:13.11.1-ee.0"
        ports = ["https"]
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
        }

        check {
          name            = "service: gitlab readiness check"
          type            = "http"
          interval        = "30s"
          timeout         = "5s"
          path            = "/-/readiness?token="
          protocol        = "https"
          tls_skip_verify = true
        }

        check {
          name            = "service: gitlab liveness check"
          type            = "http"
          interval        = "30s"
          timeout         = "5s"
          path            = "/-/liveness?token="
          protocol        = "https"
          tls_skip_verify = true
        }
      }

      resources {
        cpu    = 1609
        memory = 4096
      }

      scaling "cpu" {
        enabled = true
        min     = 50
        max     = 4000

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
        min     = 2048
        max     = 4096

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

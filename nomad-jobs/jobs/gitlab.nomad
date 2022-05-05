variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "gitlab_health_check_token" {
  type    = string
  default = ""
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

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

      port "registry_https" {
        to = 5050
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
        image = "gitlab/gitlab-ee:14.5.4-ee.0"
        ports = ["https", "registry_https"]
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
          "traefik.http.routers.gitlab.rule=Host(`gitlab.${var.domain}`)",
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
            grace = "300s"
          }
        }

        check {
          name     = "service: gitlab readiness check"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/-/readiness?token=${var.gitlab_health_check_token}"
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "300s"
          }
        }

        check {
          name     = "service: gitlab liveness check"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/-/liveness?token=${var.gitlab_health_check_token}"
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "300s"
          }
        }
      }

      service {
        name = "gitlab-registry"
        port = "registry_https"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.gitlab-registry.entryPoints=websecure",
          "traefik.http.routers.gitlab-registry.rule=Host(`gitlab-registry.${var.domain}`)",
          "traefik.http.routers.gitlab-registry.tls=true",
          "traefik.http.services.gitlab-registry.loadbalancer.server.scheme=https",
        ]

        check {
          name     = "service: gitlab registry tcp check"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "300s"
          }
        }

        check {
          name     = "service: gitlab registry readiness check"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/"
          protocol = "https"

          success_before_passing   = "3"
          failures_before_critical = "3"

          check_restart {
            limit = 3
            grace = "300s"
          }
        }
      }

      template {
        destination = "secrets/certs/gitlab.${var.domain}.crt"
        perms       = "640"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=gitlab.service.consul" $ip_sans }}
{{ .Data.certificate }}{{ end }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=gitlab.service.consul" $ip_sans }}
{{ .Data.issuing_ca }}{{ end }}
          EOF
      }

      template {
        destination = "secrets/certs/gitlab.${var.domain}.key"
        perms       = "400"
        data        = <<EOF
{{ $ip_sans := printf "ip_sans=%s" (env "NOMAD_IP_https") }}
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=gitlab.service.consul" $ip_sans }}
{{ .Data.private_key }}{{ end }}
          EOF
      }

      resources {
        cpu    = 1897
        memory = 4805
      }

      scaling "cpu" {
        enabled = true
        max     = 4000

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
        max     = 6144

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

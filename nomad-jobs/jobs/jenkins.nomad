job "jenkins" {
  datacenters = ["dc1"]

  group "jenkins" {
    network {
      port "http" {}

      port "worker" {}
    }

    volume "jenkins" {
      type            = "csi"
      source          = "jenkins"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "jenkins" {
      driver = "java"

      volume_mount {
        volume      = "jenkins"
        destination = "/data"
      }

      env {
        JENKINS_HOME             = "/data"
        JENKINS_SLAVE_AGENT_PORT = "${NOMAD_PORT_worker}"
      }

      config {
        args        = ["--httpPort=${NOMAD_PORT_http}"]
        jar_path    = "local/jenkins.war"
        jvm_options = ["-Xmx768m", "-Xms384m"]
      }

      artifact {
        source = "https://get.jenkins.io/war-stable/2.303.1/jenkins.war"

        options {
          checksum = "sha256:4aae135cde63e398a1f59d37978d97604cb595314f7041d2d3bac3f0bb32c065"
        }
      }

      service {
        port = "http"
        name = "jenkins"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.jenkins.entryPoints=websecure",
          "traefik.http.routers.jenkins.rule=Host(`jenkins.hashidemos.io`)",
          "traefik.http.routers.jenkins.tls=true",
        ]

        check {
          type     = "http"
          path     = "/login"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }

      resources {
        cpu    = 2400
        memory = 768
      }

      scaling "cpu" {
        enabled = true
        max     = 2400

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
        max     = 2048

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
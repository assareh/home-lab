job "internet-monitoring" {
  datacenters = ["dc1"]

  priority = 15

  group "speedtest-exporter" {
    network {
      port "speedtest_exporter" {}
    }

    task "speedtest-exporter" {
      driver = "docker"

      config {
        image = "ghcr.io/miguelndecarvalho/speedtest-exporter:v3.3.2"
        ports = ["speedtest_exporter"]
      }

      env {
        SPEEDTEST_PORT = "${NOMAD_PORT_speedtest_exporter}"
      }

      resources {
        cpu    = 57
        memory = 26
      }

      service {
        name = "prometheus-speedtest-exporter"
        port = "speedtest_exporter"

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

      scaling "cpu" {
        enabled = true
        max     = 500

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
        max     = 512

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

  group "blackbox-exporter" {
    network {
      port "blackbox_exporter" {}
    }

    task "blackbox-exporter" {
      driver = "docker"

      config {
        image = "prom/blackbox-exporter:v0.19.0"
        ports = ["blackbox_exporter"]

        args = [
          "--config.file=local/config/blackbox.yml",
          "--web.listen-address=:${NOMAD_PORT_blackbox_exporter}",
        ]
      }

      resources {
        cpu    = 287
        memory = 20
      }

      template {
        data = <<EOH
---
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      method: GET
      valid_status_codes: [200]
      preferred_ip_protocol: ip4
      follow_redirects: true
      fail_if_not_ssl: true
  http_post_2xx:
    prober: http
    http:
      method: POST
  tcp_connect:
    prober: tcp
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
      - send: "SSH-2.0-blackbox-ssh-check"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
  icmp:
    prober: icmp
EOH

        destination = "local/config/blackbox.yml"
      }

      service {
        name = "prometheus-blackbox-exporter"
        port = "blackbox_exporter"

        check {
          type     = "http"
          path     = "/metrics"
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

      scaling "cpu" {
        enabled = true
        max     = 500

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
        min     = 20 # less than this will fail to start
        max     = 512

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

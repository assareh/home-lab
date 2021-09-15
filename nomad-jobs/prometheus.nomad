job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
    network {
      port "prometheus_ui" {
        static = 9091
        to     = 9090
      }
    }

    volume "prometheus" {
      type            = "csi"
      source          = "prometheus"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "prometheus" {
      driver = "docker"

      volume_mount {
        volume      = "prometheus"
        destination = "/prometheus"
      }

      artifact {
        source      = "https://raw.githubusercontent.com/geerlingguy/internet-pi/master/internet-monitoring/prometheus/alert.rules"
        destination = "local/config/"
      }

      config {
        image = "prom/prometheus:v2.29.2"

        args = [
          "--config.file=/etc/prometheus/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--storage.tsdb.retention=90d",
          "--storage.tsdb.retention.size=30GB",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
        ]

        volumes = [
          "local/config:/etc/prometheus/config",
        ]

        ports = ["prometheus_ui"]
      }

      template {
        data = <<EOH
---
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    monitor: 'Alertmanager'

rule_files:
  - 'alert.rules'

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: nomad
    metrics_path: '/v1/metrics'
    params:
      format: ['prometheus']
    static_configs:
    - targets:
        [
          '{{ with service "nomad-client" }}{{ with index . 0 }}{{.Address}}:{{.Port}}{{ end }}{{ end }}'
        ]

  - job_name: consul
    metrics_path: '/v1/agent/metrics'
    params:
      format: ['prometheus']
    static_configs:
    - targets: 
        [
          '{{ with service "consul" }}{{ with index . 0 }}{{.Address}}{{ end }}{{ end }}:8500'
        ]

  - job_name: 'edinburgh'
    metrics_path: '/metrics'
    static_configs:
    - targets: 
        [
          '{{ with service "prometheus-esxi-exporter" }}{{ with index . 0 }}{{.Address}}:{{.Port}}{{ end }}{{ end }}'
        ]
      labels:
        alias: edinburgh

  - job_name: 'pihole'
    static_configs:
    - targets: 
        [
          '{{ with service "prometheus-pihole-exporter" }}{{ with index . 0 }}{{.Address}}:{{.Port}}{{ end }}{{ end }}'
        ]

  - job_name: 'speedtest-exporter'
    scrape_interval: 1h
    scrape_timeout: 1m
    static_configs:
    - targets: 
        [
          '{{ with service "prometheus-speedtest-exporter" }}{{ with index . 0 }}{{.Address}}:{{.Port}}{{ end }}{{ end }}'
        ]
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      resources {
        cpu    = 100
        memory = 256
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
        min     = 64
        max     = 512

        policy {
          cooldown            = "5m"
          evaluation_interval = "30s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      service {
        name = "prometheus"
        port = "prometheus_ui"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit = 3
            grace = "60s"
          }
        }
      }
    }
  }
}

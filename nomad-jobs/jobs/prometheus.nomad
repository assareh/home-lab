job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
    vault {
      policies = ["consul-client-tls"]
    }

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
      - targets: ['localhost:{{env "NOMAD_PORT_prometheus_ui"}}']

  - job_name: nomad
    metrics_path: '/v1/metrics'
    params:
      format: ['prometheus']
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['nomad-client', 'nomad']
      tags: ['http']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'

  - job_name: consul
    metrics_path: '/v1/agent/metrics'
    params:
      format: ['prometheus']
    tls_config: 
      ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
      cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
      key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'
    scheme: 'https'
    static_configs:
    - targets: 
        [
          {{range $index, $service := service "consul" "any"}}{{if ne $index 0}}, {{end}}'{{.Address}}:8501'{{end}}
        ]

  - job_name: 'edinburgh'
    metrics_path: '/metrics'
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['prometheus-esxi-exporter']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'

  - job_name: 'pihole'
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['prometheus-pihole-exporter']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'

  - job_name: 'cloudflared'
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['prometheus-cloudflared-metrics']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'

  - job_name: 'blackbox-exporter'
    metrics_path: /probe
    params:
      module: [http_2xx] # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - https://status.aws.amazon.com
        - https://status.cloud.google.com
        - https://status.azure.com
        - https://www.apple.com/support/systemstatus/
    relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: {{ with service "prometheus-blackbox-exporter" }}{{ with index . 0 }}{{.Address}}:{{.Port}}{{ end }}{{ end }} # The blackbox exporter's real hostname:port.

  - job_name: 'speedtest-exporter'
    scrape_interval: 1h
    scrape_timeout: 1m
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['prometheus-speedtest-exporter']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'

  - job_name: 'nodeexp'
    static_configs:
    consul_sd_configs: 
    - server: 'consul.service.consul:8501' 
      datacenter: 'dc1'
      scheme: 'https'
      services: ['node-exporter']
      tls_config: 
        ca_file: '{{ env "NOMAD_SECRETS_DIR" }}/ca.pem'
        cert_file: '{{ env "NOMAD_SECRETS_DIR" }}/cert.pem'
        key_file: '{{ env "NOMAD_SECRETS_DIR" }}/key.pem'
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      template {
        destination = "secrets/ca.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=prometheus.client.dc1.consul" }}
{{ .Data.issuing_ca }}{{ end }}
EOF
      }

      template {
        destination = "secrets/cert.pem"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=prometheus.client.dc1.consul" }}
{{ .Data.certificate }}{{ end }}
EOF
      }

      template {
        destination = "secrets/key.pem"
        perms       = "444"
        data        = <<EOF
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=prometheus.client.dc1.consul" }}
{{ .Data.private_key }}{{ end }}
EOF
      }

      resources {
        cpu    = 500
        memory = 300
      }

      scaling "cpu" {
        enabled = true
        max     = 500

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
        max     = 512

        policy {
          cooldown            = "24h"
          evaluation_interval = "24h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      service {
        name = "prometheus"
        port = "prometheus_ui"

        tags = [
          "dnsmasq.cname=true",
          "traefik.enable=true",
          "traefik.http.routers.prometheus.entryPoints=websecure",
          "traefik.http.routers.prometheus.rule=Host(`prometheus.hashidemos.io`)",
          "traefik.http.routers.prometheus.tls=true",
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
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
    }
  }
}

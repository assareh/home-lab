provider "nomad" {
  address = var.nomad_addr
}

data "nomad_plugin" "nas" {
  plugin_id        = "nas"
  wait_for_healthy = true
}

//!-------------- volumes ------------------------>
resource "nomad_external_volume" "code_server" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "code_server"
  name         = "code_server"
  capacity_min = "1G"
  capacity_max = "5G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "consul_snapshots" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "consul_snapshots"
  name         = "consul_snapshots"
  capacity_min = "70M"
  capacity_max = "210M"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "docker_registry" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "docker_registry"
  name         = "docker_registry"
  capacity_min = "10M"
  capacity_max = "5G"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "gitlab_config" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_config"
  name         = "gitlab_config"
  capacity_min = "1M"
  capacity_max = "10M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "gitlab_data" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_data"
  name         = "gitlab_data"
  capacity_min = "1G"
  capacity_max = "5G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "gitlab_logs" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_logs"
  name         = "gitlab_logs"
  capacity_min = "3G"
  capacity_max = "12G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "grafana_etc" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "grafana_etc"
  name         = "grafana_etc"
  capacity_min = "5M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "grafana_lib" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "grafana_lib"
  name         = "grafana_lib"
  capacity_min = "5M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "homebridge" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "homebridge"
  name         = "homebridge"
  capacity_min = "10M"
  capacity_max = "100M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "influxdb" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "influxdb"
  name         = "influxdb"
  capacity_min = "10G"
  capacity_max = "30G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "jenkins" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "jenkins"
  name         = "jenkins"
  capacity_min = "10M"
  capacity_max = "500M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "nomad_snapshots" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "nomad_snapshots"
  name         = "nomad_snapshots"
  capacity_min = "70M"
  capacity_max = "210M"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "prometheus" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "prometheus"
  name         = "prometheus"
  capacity_min = "10G"
  capacity_max = "30G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "splunk_etc" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "splunk_etc"
  name         = "splunk_etc"
  capacity_min = "1G"
  capacity_max = "3G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "splunk_var" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "splunk_var"
  name         = "splunk_var"
  capacity_min = "30G"
  capacity_max = "100G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "traefik" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "traefik"
  name         = "traefik"
  capacity_min = "10M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "nomad_external_volume" "unifi" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "unifi"
  name         = "unifi"
  capacity_min = "500M"
  capacity_max = "5G"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = false
  }
}

//!-------------- jobs ------------------------>
resource "nomad_job" "code_server" {
  jobspec    = file("${path.module}/jobs/code-server.nomad")
  depends_on = [nomad_external_volume.code_server, nomad_job.docker_registry]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "dns_servers"     = var.dns_servers,
      "domain"          = var.domain,
      "vault_cert_role" = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "consul-backups" {
  jobspec    = file("${path.module}/jobs/consul-backups.nomad")
  depends_on = [nomad_external_volume.consul_snapshots]
}

resource "nomad_job" "consul-esm" {
  jobspec = file("${path.module}/jobs/consul-esm.nomad")
}

// not currently available in nomad provider
// resource "nomad_job" "consul-ingress-gateway" {
//   jobspec = file("${path.module}/jobs/consul-ingress-gateway.nomad")
// }

// not currently available in nomad provider
// resource "nomad_job" "consul-mesh-gateway" {
//   jobspec = file("${path.module}/jobs/consul-mesh-gateway.nomad")
// }

resource "nomad_job" "countdash" {
  jobspec = file("${path.module}/jobs/countdash.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

resource "nomad_job" "docker_registry" {
  jobspec    = file("${path.module}/jobs/docker-registry.nomad")
  depends_on = [nomad_external_volume.docker_registry]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "vault_cert_role" = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "fluentd" {
  jobspec    = file("${path.module}/jobs/fluentd.nomad")
  depends_on = [nomad_job.docker_registry]
}

resource "nomad_job" "gitlab" {
  jobspec    = file("${path.module}/jobs/gitlab.nomad")
  depends_on = [nomad_external_volume.gitlab_config, nomad_external_volume.gitlab_data, nomad_external_volume.gitlab_logs]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"                    = var.domain,
      "gitlab_health_check_token" = var.gitlab_health_check_token
      "vault_cert_role"           = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "gitlab-runner" {
  jobspec = file("${path.module}/jobs/gitlab-runner.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "dns_servers"     = var.dns_servers,
      "domain"          = var.domain,
      "vault_cert_role" = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "google-dns-updater" {
  jobspec = file("${path.module}/jobs/google-dns-updater.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"         = var.domain,
      "google_project" = var.google_project,
    }
  }
}

resource "nomad_job" "grafana" {
  jobspec    = file("${path.module}/jobs/grafana.nomad")
  depends_on = [nomad_external_volume.grafana_etc, nomad_external_volume.grafana_lib]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

resource "nomad_job" "homebridge" {
  jobspec    = file("${path.module}/jobs/homebridge.nomad")
  depends_on = [nomad_external_volume.homebridge, nomad_job.docker_registry]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"          = var.domain,
      "vault_cert_role" = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "influxdb" {
  jobspec    = file("${path.module}/jobs/influxdb.nomad")
  depends_on = [nomad_external_volume.influxdb]
}

resource "nomad_job" "internet-monitoring" {
  jobspec = file("${path.module}/jobs/internet-monitoring.nomad")
}

// resource "nomad_job" "jenkins" {
//   jobspec    = file("${path.module}/jobs/jenkins.nomad")
//   depends_on = [nomad_external_volume.jenkins]

//   hcl2 {
//     enabled  = true
//     allow_fs = true
//     vars = {
//       "domain" = var.domain,
//     }
//   }
// }

resource "nomad_job" "node-exporter" {
  jobspec = file("${path.module}/jobs/node-exporter.nomad")
}

resource "nomad_job" "nomad-autoscaler" {
  jobspec = file("${path.module}/jobs/nomad-autoscaler.nomad")
}

resource "nomad_job" "nomad-backups" {
  jobspec    = file("${path.module}/jobs/nomad-backups.nomad")
  depends_on = [nomad_external_volume.nomad_snapshots]
}

resource "nomad_job" "pi-hole" {
  jobspec = file("${path.module}/jobs/pi-hole.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"      = var.domain,
      "subnet_cidr" = var.subnet_cidr,
    }
  }
}

resource "nomad_job" "prometheus" {
  jobspec    = file("${path.module}/jobs/prometheus.nomad")
  depends_on = [nomad_external_volume.prometheus]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

resource "nomad_job" "prometheus-esxi-exporter" {
  jobspec = file("${path.module}/jobs/prometheus-esxi-exporter.nomad")
}

resource "nomad_job" "speedtest" {
  jobspec = file("${path.module}/jobs/speedtest.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

resource "nomad_job" "splunk" {
  jobspec    = file("${path.module}/jobs/splunk.nomad")
  depends_on = [nomad_external_volume.splunk_etc, nomad_external_volume.splunk_var]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

resource "nomad_job" "telegraf" {
  jobspec = file("${path.module}/jobs/telegraf.nomad")
}

resource "nomad_job" "telegraf-devices-collector" {
  jobspec = file("${path.module}/jobs/telegraf-devices-collector.nomad")
}

resource "nomad_job" "tfc-ip-ranges-check" {
  jobspec = file("${path.module}/jobs/tfc-ip-ranges-check.nomad")
}

resource "nomad_job" "traefik" {
  jobspec    = file("${path.module}/jobs/traefik.nomad")
  depends_on = [nomad_external_volume.traefik]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"         = var.domain,
      "email"          = var.email,
      "google_project" = var.google_project,
      "subnet_cidr"    = var.subnet_cidr,
    }
  }
}

resource "nomad_job" "unifi" {
  jobspec    = file("${path.module}/jobs/unifi.nomad")
  depends_on = [nomad_external_volume.unifi]

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain"          = var.domain,
      "vault_cert_role" = var.vault_cert_role,
    }
  }
}

resource "nomad_job" "whoami" {
  jobspec = file("${path.module}/jobs/whoami.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "domain" = var.domain,
    }
  }
}

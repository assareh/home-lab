provider "nomad" {
  address = "http://nomad.service.consul:4646"
}

# Please note that filesystem functions will create an implicit dependency in your
# Terraform configuration. For example, Terraform will not be able to detect changes
# to files loaded using the file function inside a jobspec.
# https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job

resource "nomad_job" "consul-backups" {
  jobspec = file("${path.module}/consul-backups.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "consul-esm" {
  jobspec = file("${path.module}/consul-esm.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "countdash" {
  jobspec = file("${path.module}/countdash.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "das-autoscaler" {
  jobspec = file("${path.module}/das-autoscaler.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "gitlab" {
  jobspec = file("${path.module}/gitlab.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("${path.module}/grafana.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "homebridge" {
  jobspec = file("${path.module}/homebridge.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "influxdb" {
  jobspec = file("${path.module}/influxdb.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "nomad-backups" {
  jobspec = file("${path.module}/nomad-backups.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "pi-hole" {
  jobspec = file("${path.module}/pi-hole.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/prometheus.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "speedtest" {
  jobspec = file("${path.module}/speedtest.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "splunk" {
  jobspec = file("${path.module}/splunk.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "telegraf" {
  jobspec = file("${path.module}/telegraf.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "traefik" {
  jobspec = templatefile("${path.module}/traefik.nomad", {
    pilot_token = var.pilot_token
  })

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

resource "nomad_job" "unifi" {
  jobspec = file("${path.module}/unifi.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}

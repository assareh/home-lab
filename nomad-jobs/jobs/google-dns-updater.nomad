variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "google_project" {
  type    = string
  default = "hashidemos-io-dns"
}

job "google-dns-updater" {
  datacenters = ["dc1"]
  type        = "batch"

  priority = 75

  periodic {
    cron = "@daily"
  }

  group "google-dns-updater" {
    vault {
      policies = ["google-dns-updater"]
    }

    task "google-dns-updater" {
      driver = "exec"

      config {
        command = "local/google-dns-updater.sh"
      }

      template {
        data = <<EOF
API_KEY={{with secret "nomad/data/google-dns-updater"}}{{.Data.data.api_key}}{{end}}
EOF

        destination = "secrets/config.env"
        env         = true
      }

      template {
        destination = "local/google-dns-updater.sh"
        perms       = "755"

        data = <<EOS
#!/bin/bash
set -x

IPADDRESS=`curl --silent ipecho.net/plain`

generate_post_data()
{
  cat <<EOD
{
  "host":"gitlab.${var.domain}.",
  "ip":"$IPADDRESS",
  "key":"$API_KEY"
}
EOD
}

curl -X POST https://us-west2-${var.google_project}.cloudfunctions.net/dns-updater -H "Content-Type: application/json" -d "$(generate_post_data)"
EOS
      }

      resources {
        cpu    = 20
        memory = 50
      }
    }
  }
}

job "tfc-ip-ranges-check" {
  datacenters = ["dc1"]
  type        = "batch"

  priority = 25

  periodic {
    cron = "@daily"
  }

  group "tfc-ip-ranges-check" {
    vault {
      policies = ["tfc-ip-ranges-check"]
    }

    task "tfc-ip-ranges-check" {
      driver = "exec"

      config {
        command = "local/tfc-ip-ranges-check.sh"
      }

      template {
        data = <<EOF
ACCOUNT_SID={{with secret "nomad/data/tfc-ip-ranges-check"}}{{.Data.data.ACCOUNT_SID}}{{end}}
AUTH_TOKEN={{with secret "nomad/data/tfc-ip-ranges-check"}}{{.Data.data.AUTH_TOKEN}}{{end}}
TWILIO_NUMBER={{with secret "nomad/data/tfc-ip-ranges-check"}}{{.Data.data.TWILIO_NUMBER}}{{end}}
SENDTO_NUMBER={{with secret "nomad/data/tfc-ip-ranges-check"}}{{.Data.data.SENDTO_NUMBER}}{{end}}
EOF

        destination = "secrets/config.env"
        env         = true
      }

      template {
        destination = "local/tfc-ip-ranges-check.sh"
        perms       = "755"

        data = <<EOS
#!/bin/bash
set -x

IP_RANGES=`(curl --silent \
  -H "If-Modified-Since: Sat, 4 Jun 2022 15:10:05 GMT" \
  https://app.terraform.io/api/meta/ip-ranges | jq -r .vcs)`

if [ -z "${IP_RANGES}" ];
then
  echo 'No change!'
else
  curl -X POST -d "Body=Terraform Cloud VCS source IPs: $IP_RANGES" \
  -d "From=$TWILIO_NUMBER" -d "To=$SENDTO_NUMBER" \
  "https://api.twilio.com/2010-04-01/Accounts/$ACCOUNT_SID/Messages" \
  -u "$ACCOUNT_SID:$AUTH_TOKEN"
fi
EOS
      }

      resources {
        cpu    = 20
        memory = 50
      }
    }
  }
}

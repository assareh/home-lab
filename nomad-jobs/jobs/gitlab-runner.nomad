variable "dns_servers" {
  type = list(string)
}

variable "domain" {
  type    = string
  default = "hashidemos.io"
}

variable "vault_cert_role" {
  type    = string
  default = "hashidemos-io"
}

job "gitlab-runner" {
  datacenters = ["dc1"]

  group "gitlab-runner" {
    vault {
      policies = ["gitlab-runner", "pki"]
    }

    restart {
      attempts = 1
    }

    task "gitlab-runner" {
      driver = "docker"

      # weird that it doesn't register by default
      # can manually register the runner with api call, then put the token in vault
      # curl --request POST "https://gitlab.${var.domain}/api/v4/runners" \
      # --form "token=$GITLAB_TOKEN" --form "description=manually-registered" \
      # --form "tag_list=packer"
      # or just run once and save the config to persistent storage once registered
      # currently must
      # nomad alloc exec -task gitlab-runner -job gitlab-runner /bin/sh
      # gitlab-runner register
      config {
        image       = "gitlab/gitlab-runner:alpine3.13-v14.5.2"
        dns_servers = var.dns_servers
        volumes = [
          "local/config.toml:/etc/gitlab-runner/config.toml",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      env { # these are used during the first time registration
        CI_SERVER_URL            = "https://gitlab.${var.domain}"
        DOCKER_IMAGE             = "alpine:latest"
        REGISTER_LOCKED          = "false"
        REGISTER_NON_INTERACTIVE = "true"
        REGISTER_RUN_UNTAGGED    = "true"
        RUNNER_EXECUTOR          = "docker"
        RUNNER_NAME              = "gitlab-runner-nomad"
        RUNNER_TAG_LIST          = "packer"
      }

      resources {
        cpu    = 35 # this is not the runner, this is the helper - which spawns other containers to do worker
        memory = 256
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
        max     = 4096

        policy {
          cooldown            = "72h"
          evaluation_interval = "72h"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      template {
        destination = "local/config.toml"
        change_mode = "restart"
        data        = <<EOF
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "gitlab-runner-nomad"
  url = "https://gitlab.${var.domain}"
  token = "{{with secret "nomad/data/gitlab-runner"}}{{.Data.data.AUTHENTICATION_TOKEN}}{{end}}"
  executor = "docker"

    # Copy and install CA certificate before each job
    pre_build_script = """
    apk update >/dev/null
    apk add ca-certificates > /dev/null
    rm -rf /var/cache/apk/*

    cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/.
    update-ca-certificates --fresh > /dev/null
    """

  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache", "/opt/nomad/alloc/{{ env "NOMAD_ALLOC_ID" }}/alloc/ca.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
    shm_size = 0
EOF
      }

      template { # this is only used during the initial one time registration
        data = <<EOH
REGISTRATION_TOKEN="{{with secret "nomad/data/gitlab-runner"}}{{.Data.data.REGISTRATION_TOKEN}}{{end}}"
                   EOH

        destination = "secrets/config.env"
        env         = true
      }

      template { # this is passed through to the worker so it can verify TLS for Vault and ESXi 
        destination = "${NOMAD_ALLOC_DIR}/ca.crt"
        perms       = "644"
        data        = <<EOF
{{ with secret "pki/intermediate/issue/${var.vault_cert_role}" "common_name=bogus.service.consul" }}{{ .Data.issuing_ca }}{{ end }}
          EOF
      }
    }
  }
}
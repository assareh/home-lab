job "consul-ingress-gateway" {
  datacenters = ["dc1"]

  group "ingress-group" {
    network {
      mode = "bridge"

      port "inbound" {
        static = 8010
      }
    }

    service {
      name = "ingress-gateway"
      port = "inbound"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"
      }

      connect {
        gateway {
          # Consul Ingress Gateway Configuration Entry.
          ingress {
            # Nomad will automatically manage the Configuration Entry in Consul
            # given the parameters in the ingress block.
            #
            # Additional options are documented at
            # https://www.nomadproject.io/docs/job-specification/gateway#ingress-parameters
            listener {
              port     = 8010
              protocol = "http"
              service {
                name  = "web-dc2"
                hosts = ["*"]
              }
            }
          }

          proxy {
          }
        }

        sidecar_task {
          resources {
            cpu    = 35
            memory = 128
          }
        }
      }
    }
  }
}
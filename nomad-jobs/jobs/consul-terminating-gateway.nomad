job "consul-terminating-gateway" {
  datacenters = ["dc1"]

  group "gateway" {
    network {
      mode = "bridge"
    }

    service {
      name = "terminating-gateway"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"
      }

      connect {
        sidecar_task {
          resources {
            cpu    = 35
            memory = 128
          }
        }
        gateway {
          proxy {
          }

          # Consul Terminating Gateway Configuration Entry.
          terminating {
            # Nomad will automatically manage the Configuration Entry in Consul
            # given the parameters in the terminating block.
            #
            # Additional options are documented at
            # https://www.nomadproject.io/docs/job-specification/gateway#terminating-parameters
            service {
              name = "hue-api"
            }
          }
        }
      }
    }
  }
}
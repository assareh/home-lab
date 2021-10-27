job "consul-mesh-gateway" {
  datacenters = ["dc1"]

  group "mesh-gateway-one" {
    network {
      mode = "bridge"

      port "mesh_wan" {
        static = "9100"
      }
    }

    service {
      name = "mesh-gateway"
      port = "mesh_wan"

      meta {
        consul-wan-federation = "1"
      }

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = "3"
        failures_before_critical = "3"
      }

      connect {
        gateway {
          mesh {
          }

          proxy {
          }
        }

        sidecar_task {
          resources {
            cpu    = 100
            memory = 128
          }
        }
      }
    }
  }
}
job "unbound" {
  datacenters = ["dc1"]

  group "unbound" {
    network {
      port "dns" {
        static = 53
      }
    }

    task "unbound" {
      driver = "docker"

      config {
        image        = "mvance/unbound"
        network_mode = "host"
      }

      resources {
        cpu    = 35
        memory = 128
      }
    }
  }
}

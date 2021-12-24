job "example" {
  datacenters = ["dc1"]
  type        = "service"

  group "example" {
    volume "example" {
      type            = "csi"
      source          = "example"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "example" {
      driver = "docker"

      config {
        image = "ubuntu"

        args = [
          "sleep",
          "infinity",
        ]

      }

      volume_mount {
        volume      = "example"
        destination = "/mnt"
      }

      resources {
        cpu    = 150
        memory = 256
      }
    }
  }
}

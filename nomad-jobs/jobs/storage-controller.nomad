job "storage-controller" {
  datacenters = ["dc1"]

  priority = 100

  group "controller" {
    count = 2

    task "controller" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.3.0"

        args = [
          "--type=controller",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=nfs.service.consul:/data",
          "--mount-options=defaults", # Adjust accordingly
        ]

        network_mode = "host" # required so the mount works even after stopping the container
      }

      csi_plugin {
        id        = "nas"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 20
        memory = 27
      }
    }
  }
}

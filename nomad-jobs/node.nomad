job "storage-node" {
  datacenters = ["dc1"]
  type        = "system"

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.3.0"

        args = [
          "--type=node",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=nfs.service.consul:/data",
          "--mount-options=defaults", # Adjust accordingly
        ]

        network_mode = "host" # required so the mount works even after stopping the container

        privileged = true
      }

      csi_plugin {
        id        = "nas"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}

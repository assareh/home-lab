job "storage-node" {
  datacenters = ["dc1"]
  type        = "system"

  priority = 95

  constraint {
    attribute = "${node.class}"
    value     = "castle"
  }

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

        # all CSI node plugins will need to run as privileged tasks
        # so they can mount volumes to the host. controller plugins
        # do not need to be privileged.
        privileged = true
      }

      csi_plugin {
        id        = "nas"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 20
        memory = 34
      }
    }
  }
}

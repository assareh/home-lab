job "tinycore" {
  datacenters = ["dc1"]

  group "tinycore" {
    network {
      port "http" {}
      port "ssh" {}
    }

    task "tinycore" {
      driver = "qemu"

      artifact {
        source      = "https://github.com/angrycub/nomad_example_jobs/raw/main/qemu/tinycore.qcow2"
        destination = "local/"
      }

      config {
        image_path = "local/tinycore.qcow2" # make sure path is allowed in nomad client plugin options

        ## Uncomment if KVM is available on your system
        accelerator = "kvm"

        args = [
          "-device",
          "e1000,netdev=user.0",
          "-netdev",
          "user,id=user.0,hostfwd=tcp::${NOMAD_PORT_http}-:80,hostfwd=tcp::${NOMAD_PORT_ssh}-:22",
        ]
      }

      service {
        name = "tinycore-ssh"
        port = "ssh"

        check {
          type     = "tcp"
          port     = "ssh"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
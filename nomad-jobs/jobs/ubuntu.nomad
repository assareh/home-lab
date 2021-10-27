# how to increase disk in ubuntu cloud image
# qemu-img resize ubuntu-18.04-server-cloudimg-amd64.img +18G
# prepare seed image
# on linux
# cloud-localds -v userdata.img cloud_init.cfg
# on mac
# serve it up on a local http server

job "ubuntu" {
  datacenters = ["dc1"]

  group "ubuntu" {
    network {
      port "ssh" {}
    }

    task "ubuntu" {
      driver = "qemu"

      artifact {
        source      = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
        destination = "local/"
      }

      artifact {
        source      = "http://192.168.0.20:8080/userdata.img"
        destination = "local/"
      }

      config {
        image_path = "local/ubuntu-18.04-server-cloudimg-amd64.img" # make sure path is allowed in nomad client plugin options

        accelerator = "kvm"

        args = [
          "-device",
          "e1000,netdev=user.0",
          "-netdev",
          "user,id=user.0,hostfwd=tcp::${NOMAD_PORT_ssh}-:22",
          "-cdrom",
          "local/userdata.img"
        ]
      }

      resources {
        cpu    = 2000
        memory = 2048
      }

      service {
        name = "ubuntu-ssh"
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
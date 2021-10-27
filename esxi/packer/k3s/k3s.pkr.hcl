# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vmware-iso" "ubuntu-20-k3s" {
  boot_command = [
    "<enter><wait2><enter><wait><f6><esc><wait>",
    " autoinstall<wait2> ds=nocloud",
    "<wait><enter>"
  ]
  boot_wait              = "5s"
  cd_files               = ["./meta-data", "./user-data"]
  cd_label               = "cidata"
  cpus                   = "${var.vm_cpu_num}"
  disk_size              = "${var.vm_disk_size}"
  disk_type_id           = "thin"
  guest_os_type          = "ubuntu-64"
  headless               = "false"
  iso_checksum           = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
  iso_url                = "https://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso"
  keep_registered        = true
  memory                 = "${var.vm_mem_size}"
  network_adapter_type   = "vmxnet3"
  network_name           = "${var.network_name}"
  remote_datastore       = "${var.remote_datastore}"
  remote_host            = "${var.esxi_host}"
  remote_password        = "${local.esxi_password}"
  remote_port            = 22
  remote_type            = "esx5"
  remote_username        = "${local.esxi_username}"
  shutdown_command       = "sudo -S shutdown -P now"
  skip_export            = true
  ssh_handshake_attempts = "1000"
  ssh_password           = "${local.ssh_password}"
  ssh_timeout            = "1200s"
  ssh_username           = "${var.ssh_username}"
  vm_name                = "${local.vm_name}"
  vmx_data = {
    "virtualhw.version" = "17"
  }
  vmx_data_post = {
    "bios.bootorder"        = "hdd"
    "ide0:0.startConnected" = "FALSE"
    "ide0:1.startConnected" = "FALSE"
    "ide1:0.startConnected" = "FALSE"
    "ide1:1.startConnected" = "FALSE"
    "ide0:0.deviceType"     = "cdrom-raw"
    "ide0:1.deviceType"     = "cdrom-raw"
    "ide1:0.deviceType"     = "cdrom-raw"
    "ide1:1.deviceType"     = "cdrom-raw"
    "ide0:0.clientDevice"   = "TRUE"
    "ide0:1.clientDevice"   = "TRUE"
    "ide1:0.clientDevice"   = "TRUE"
    "ide1:1.clientDevice"   = "TRUE"
    "ide0:0.present"        = "FALSE"
    "ide0:1.present"        = "FALSE"
    "ide1:0.present"        = "TRUE"
    "ide1:1.present"        = "FALSE"
    "ide0:0.fileName"       = "emptyBackingString"
    "ide0:1.fileName"       = "emptyBackingString"
    "ide1:0.fileName"       = "emptyBackingString"
    "ide1:1.fileName"       = "emptyBackingString"
  }
  vnc_over_websocket = "true"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.vmware-iso.ubuntu-20-k3s"]

  provisioner "file" {
    destination = "/home/${var.ssh_username}/"
    source      = "files/"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "SSH_USERNAME=${var.ssh_username}"
    ]
    execute_command = "{{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "scripts/docker.sh",
      "scripts/k8s.sh",
      "scripts/k3s.sh",
      "scripts/dashboard.sh",
      "scripts/user.sh"
    ]
  }
}

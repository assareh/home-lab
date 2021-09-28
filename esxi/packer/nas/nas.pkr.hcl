# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vmware-iso" "ubuntu-20-nas" {
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
  vnc_over_websocket = "true"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.vmware-iso.ubuntu-20-nas"]

  provisioner "file" {
    destination = "/home/${var.ssh_username}/"
    source      = "files/"
  }

  provisioner "shell" {
    inline = [
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y consul=${var.consul_version}",
      "sudo apt-get autoremove -y",
      "sudo -H -u ${var.ssh_username} consul -autocomplete-install"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get install -y prometheus-node-exporter",
      "sudo systemctl start prometheus-node-exporter.service",
      "sudo systemctl enable prometheus-node-exporter.service"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "consul_gossip=${local.consul_gossip}"
    ]
    inline = [
      "sudo mv /home/${var.ssh_username}/consul.hcl /etc/consul.d/.",
      "sudo mv /home/${var.ssh_username}/nfs.json /etc/consul.d/.",
      "sudo mv /home/${var.ssh_username}/node-exporter.json /etc/consul.d/.",
      "chmod +x /home/${var.ssh_username}/gossip.sh",
      "/home/${var.ssh_username}/gossip.sh",
      "sudo chmod 640 /etc/consul.d/*",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo hostnamectl set-hostname nas",
      "echo '127.0.1.1       nas.unassigned-domain        nas' | sudo tee -a /etc/hosts",
      "sudo systemctl enable consul && sudo systemctl start consul"
    ]
  }
}

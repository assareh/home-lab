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
  iso_checksum           = var.iso_checksum
  iso_url                = var.iso_url
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
  sources = ["source.vmware-iso.ubuntu-20-nas"]

  provisioner "file" {
    destination = "/home/${var.ssh_username}/"
    source      = "files/"
  }

  # install Consul
  provisioner "shell" {
    inline = [
      "curl --silent -O https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip",
      "curl --silent -O https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_SHA256SUMS",
      "shasum -c --ignore-missing consul_${var.consul_version}_SHA256SUMS",
      "unzip -o consul_${var.consul_version}_linux_amd64.zip",
      "sudo chown root:root consul",
      "sudo mv consul /usr/bin/",
      "consul --version",
      "sudo -H -u ${var.ssh_username} consul -autocomplete-install",
      "sudo useradd --system --home /etc/consul.d --shell /bin/false consul",
      "sudo mkdir -p -m 755 /opt/consul /etc/consul.d",
      "sudo chown -R consul:consul /opt/consul /etc/consul.d",
      "sudo mv /home/${var.ssh_username}/consul.service /usr/lib/systemd/system/consul.service",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get autoremove -y"
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
      "sudo mv /home/${var.ssh_username}/consul-agent-ca.pem /etc/consul.d/.",
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

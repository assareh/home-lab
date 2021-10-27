# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vmware-iso" "ubuntu-20-castle" {
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
  sources = ["source.vmware-iso.ubuntu-20-castle"]

  provisioner "file" {
    destination = "/home/${var.ssh_username}/"
    source      = "files/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/${var.ssh_username}/root.crt /usr/local/share/ca-certificates/",
      "sudo update-ca-certificates"
    ]
  }

  provisioner "shell" {
    inline = [
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nomad-enterprise=${var.nomad_version} vault-enterprise=${var.vault_version} consul-enterprise=${var.consul_version}",
      "sudo apt-get autoremove -y",
      "sudo -H -u ${var.ssh_username} nomad -autocomplete-install",
      "sudo -H -u ${var.ssh_username} consul -autocomplete-install",
      "sudo -H -u ${var.ssh_username} vault -autocomplete-install"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/cni/bin/",
      "curl -LO https://github.com/containernetworking/plugins/releases/download/v${var.cni_version}/cni-plugins-linux-amd64-v${var.cni_version}.tgz",
      "sudo tar -xzf cni-plugins-linux-amd64-v${var.cni_version}.tgz -C /opt/cni/bin/"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt install -y apt-transport-https gnupg2",
      "curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/getenvoy.list",
      "sudo apt update",
      "sudo apt install -y getenvoy-envoy"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/nomad/plugins",
      "curl -OL https://github.com/Roblox/nomad-driver-containerd/releases/download/v${var.containerd_version}/containerd-driver",
      "sudo mv containerd-driver /opt/nomad/plugins/."
    ]
  }

  provisioner "shell" {
    inline = [
      "chmod +x /home/${var.ssh_username}/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle",
      "sudo /home/${var.ssh_username}/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --eulas-agreed --required --console"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/${var.ssh_username}/vault.service /usr/lib/systemd/system/vault.service",
      "sudo systemctl daemon-reload",
      "sudo touch /var/log/vault_audit.log",
      "sudo chown vault:vault /var/log/vault_audit.log",
      "sudo touch /var/log/vault_audit.pos",
      "sudo chmod 666 /var/log/vault_audit.pos"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo chown -R nomad:nomad /opt/nomad",
      "sudo chmod -R 700 /opt/nomad"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "consul_license=${local.consul_license}",
      "nomad_license=${local.nomad_license}",
      "vault_license=${local.vault_license}"
    ]
    inline = [
      "touch /home/${var.ssh_username}/consul.hclic",
      "echo $consul_license >> /home/${var.ssh_username}/consul.hclic",
      "sudo mv /home/${var.ssh_username}/consul.hclic /etc/consul.d/license.hclic",
      "touch /home/${var.ssh_username}/nomad.hclic",
      "echo $nomad_license >> /home/${var.ssh_username}/nomad.hclic",
      "sudo mv /home/${var.ssh_username}/nomad.hclic /etc/nomad.d/license.hclic",
      "touch /home/${var.ssh_username}/vault.hclic",
      "echo $vault_license >> /home/${var.ssh_username}/vault.hclic",
      "sudo mv /home/${var.ssh_username}/vault.hclic /etc/vault.d/license.hclic",
      "sudo chown vault:vault /etc/vault.d/license.hclic",
      "sudo chmod 640 /etc/vault.d/license.hclic"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "consul_gossip=${local.consul_gossip}",
      "nomad_gossip=${local.nomad_gossip}"
    ]
    inline = [
      "sudo cp /home/${var.ssh_username}/consul-agent-ca.pem /etc/vault.d/.",
      "sudo mv /home/${var.ssh_username}/consul-agent-ca.pem /etc/consul.d/.",
      "sudo mv /home/${var.ssh_username}/consul.hcl /etc/consul.d/.",
      "sudo mv /home/${var.ssh_username}/nomad.hcl /etc/nomad.d/.",
      "chmod +x /home/${var.ssh_username}/gossip.sh",
      "/home/${var.ssh_username}/gossip.sh",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo chown -R nomad:nomad /etc/nomad.d",
      "sudo chmod 640 /etc/consul.d/* /etc/nomad.d/*"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo \"export CONSUL_HTTP_ADDR=https://127.0.0.1:8501\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CLIENT_KEY=/etc/consul.d/dc1-server-consul-key.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CLIENT_CERT=/etc/consul.d/dc1-server-consul.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_HTTP_ADDR=https://127.0.0.1:8501\" | sudo tee -a /home/${var.ssh_username}/.bashrc",
      "echo \"export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem\" | sudo tee -a /home/${var.ssh_username}/.bashrc",
      "echo \"export CONSUL_CLIENT_KEY=/etc/consul.d/dc1-server-consul-key.pem\" | sudo tee -a /home/${var.ssh_username}/.bashrc",
      "echo \"export CONSUL_CLIENT_CERT=/etc/consul.d/dc1-server-consul.pem\" | sudo tee -a /home/${var.ssh_username}/.bashrc"
    ]
  }
}
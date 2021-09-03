# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vmware-iso" "ubuntu-18-castle" {
  boot_command = [
    "<enter><wait><f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs>",
    "/install/vmlinuz",
    " initrd=/install/initrd.gz",
    " priority=critical",
    " locale=en_US",
    " file=/media/preseed.cfg",
    "<enter>"
  ]
  cpus                 = "${var.vm_cpu_num}"
  disk_size            = "${var.vm_disk_size}"
  disk_type_id         = "thin"
  floppy_files         = ["./preseed.cfg"]
  guest_os_type        = "ubuntu-64"
  iso_checksum         = "sha256:8c5fc24894394035402f66f3824beb7234b757dd2b5531379cb310cedfdf0996"
  iso_url              = "https://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.5-server-amd64.iso"
  keep_registered      = true
  memory               = "${var.vm_mem_size}"
  network_adapter_type = "vmxnet3"
  network_name         = "${var.network_name}"
  remote_datastore     = "${var.remote_datastore}"
  remote_host          = "${var.esxi_host}"
  remote_password      = "${local.esxi_password}"
  remote_port          = 22
  remote_type          = "esx5"
  remote_username      = "${local.esxi_username}"
  shutdown_command     = "sudo -S shutdown -P now"
  skip_export          = true
  ssh_password         = "${local.ssh_password}"
  ssh_username         = "${var.ssh_username}"
  vm_name              = "${local.vm_name}"
  vmx_data = {
    "virtualhw.version" = "17"
  }
  vnc_over_websocket = "true"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.vmware-iso.ubuntu-18-castle"]

  provisioner "file" {
    destination = "/home/${var.ssh_username}/"
    source      = "files/"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "touch /home/${var.ssh_username}/.hushlogin",
      "mkdir -p /home/${var.ssh_username}/.ssh",
      "echo '${local.authorized_keys}' > /home/${var.ssh_username}/.ssh/authorized_keys",
      "chmod 600 /home/${var.ssh_username}/.ssh/authorized_keys",
      "chown -R ${var.ssh_username} /home/${var.ssh_username}/.ssh",
      "sudo sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config",
      "sudo service ssh restart"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/${var.ssh_username}/root.crt /usr/local/share/ca-certificates/",
      "sudo update-ca-certificates"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/${var.ssh_username}/unbound.conf /etc/unbound/unbound.conf",
      "sudo systemctl restart unbound"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir /mnt/data && sudo chmod 777 /mnt/data",
      "echo '192.168.0.55:/data    /mnt/data   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0' | sudo tee -a /etc/fstab",
      "sudo mount -a",
      "df -h"
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
      "sudo chown vault:vault /var/log/vault_audit.log"
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
      "vault_license=${local.vault_license}",
      "nomad_vault_token=${local.nomad_vault_token}"
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
    inline = [
      "sudo mv /home/${var.ssh_username}/consul.hcl /etc/consul.d/.",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo mv /home/${var.ssh_username}/nomad.hcl /etc/nomad.d/.",
      "sudo chown -R nomad:nomad /etc/nomad.d",
      "sudo chmod 640 /etc/consul.d/* /etc/nomad.d/*"
    ]
  }
}
# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vmware-iso" "ubuntu-18-nas" {
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
  disk_additional_size = ["${var.vm_disk_additional_size}"]
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
  sources = ["source.vmware-iso.ubuntu-18-nas"]

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
      "sudo mv /home/${var.ssh_username}/consul.hcl /etc/consul.d/.",
      "sudo mv /home/${var.ssh_username}/nfs.json /etc/consul.d/.",
      "sudo chmod 640 /etc/consul.d/*",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo systemctl enable consul && sudo systemctl start consul"
    ]
  }

  provisioner "breakpoint" {
    disable = true
    note    = "If mirroring the data volume, this is when you would go add the third disk. (Check Readme for details)"
  }

  provisioner "shell" {
    inline = [
      "sudo zpool create data /dev/sdb",
      "sudo chmod 777 /data",
      "echo \"/data    192.168.0.0/255.255.255.0(rw,sync,no_root_squash,no_subtree_check)\" | sudo tee -a /etc/exports",
      "sudo systemctl restart nfs-kernel-server"
    ]
  }
}

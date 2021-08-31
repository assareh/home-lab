provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

data "template_file" "setup_castle" {
  template = file("${path.module}/setup_castle.tpl")
  vars = {
    secret_id = var.secret_id
  }
}

resource "esxi_guest" "blue" {
  for_each = var.nodes_blue

  guest_name    = each.key
  disk_store    = "datastore1"
  clone_from_vm = var.template_blue
  power         = "on"

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
    mac_address     = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${each.key}",
      "echo '127.0.1.1       ${each.key}.unassigned-domain        ${each.key}' | sudo tee -a /etc/hosts"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [data.template_file.setup_castle.rendered]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

resource "esxi_guest" "green" {
  for_each = var.nodes_green

  guest_name    = each.key
  disk_store    = "datastore1"
  clone_from_vm = var.template_green
  power         = "on"

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
    mac_address     = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${each.key}",
      "echo '127.0.1.1       ${each.key}.unassigned-domain        ${each.key}' | sudo tee -a /etc/hosts"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [data.template_file.setup_castle.rendered]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

data "template_file" "setup_moat" {
  template = file("${path.module}/setup_moat.tpl")
  vars = {
    secret_id = var.secret_id
  }
}

# this is optional, for use as a DNS L4 LB
# and will be deprecated once Traefik fixes UDP
# https://github.com/traefik/traefik/issues/7430
resource "esxi_guest" "moat" {
  for_each = var.nodes_moat

  guest_name    = each.key
  disk_store    = "datastore1"
  clone_from_vm = var.template_moat
  power         = "on"

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
    mac_address     = "00:0C:29:00:00:0B"
  }

  provisioner "remote-exec" {
    inline = [data.template_file.setup_moat.rendered]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

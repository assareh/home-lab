provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described here:
  # https://registry.terraform.io/providers/hashicorp/vault/latest/docs#provider-arguments
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

resource "vault_approle_auth_backend_role_secret_id" "wrapped_secret_id" {
  role_name    = "bootstrap"
  wrapping_ttl = "420s"
  count        = 3
}

provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
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
    # setting hostname because it's used for Consul and Nomad names
    inline = [
      "sudo hostnamectl set-hostname ${lower(each.key)}",
      "echo '127.0.1.1       ${lower(each.key)}.unassigned-domain        ${lower(each.key)}' | sudo tee -a /etc/hosts",
      "echo ${vault_approle_auth_backend_role_secret_id.wrapped_secret_id[index(local.blue_hostnames, each.key)].wrapping_token} >> /home/${var.ssh_username}/secret_id",
      data.template_file.setup_castle.rendered
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }

  depends_on = [esxi_guest.nas]
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
    # setting hostname because it's used for Consul and Nomad names
    inline = [
      "sudo hostnamectl set-hostname ${lower(each.key)}",
      "echo '127.0.1.1       ${lower(each.key)}.unassigned-domain        ${lower(each.key)}' | sudo tee -a /etc/hosts",
      "echo ${vault_approle_auth_backend_role_secret_id.wrapped_secret_id[index(local.green_hostnames, each.key)].wrapping_token} >> /home/${var.ssh_username}/secret_id",
      data.template_file.setup_castle.rendered
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }

  depends_on = [esxi_guest.nas]
}

data "template_file" "setup_castle" {
  template = file("${path.module}/setup_castle.tpl")
  vars = {
    ssh_username = var.ssh_username
  }
}

resource "esxi_guest" "nas" {
  guest_name    = lookup(var.node_nas, "name")
  disk_store    = "datastore1"
  clone_from_vm = var.template_nas
  power         = "on"

  lifecycle {
    prevent_destroy = true
  }

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
    mac_address     = lookup(var.node_nas, "mac_address")
  }
}

resource "esxi_guest" "moat" {
  guest_name    = lookup(var.node_moat, "name")
  disk_store    = "datastore1"
  clone_from_vm = var.template_moat
  power         = "on"

  dynamic "network_interfaces" {
    for_each = lookup(var.node_moat, "network_interfaces")
    content {
      mac_address     = network_interfaces.value
      nic_type        = "vmxnet3"
      virtual_network = network_interfaces.key
    }
  }
}

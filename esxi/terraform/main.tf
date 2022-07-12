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
  wrapping_ttl = "600s"
  count        = 3
}

provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

resource "esxi_guest" "blue" {
  for_each = var.nodes_blue

  guest_name     = each.key
  disk_store     = var.esxi_datastore
  clone_from_vm  = var.template_blue
  boot_disk_type = "thin"
  power          = "on"

  network_interfaces {
    mac_address     = each.value
    nic_type        = "vmxnet3"
    virtual_network = var.esxi_network_name
  }

  provisioner "remote-exec" {
    inline = [ # setting hostname because it's used for Consul and Nomad names
      "sudo hostnamectl set-hostname ${lower(each.key)}",
      "echo '127.0.1.1       ${lower(each.key)}.unassigned-domain        ${lower(each.key)}' | sudo tee -a /etc/hosts",
      "echo ${vault_approle_auth_backend_role_secret_id.wrapped_secret_id[index(local.blue_hostnames, each.key)].wrapping_token} >> /home/${var.ssh_username}/secret_id",
      templatefile("${path.module}/setup_castle.tpl", { ssh_username = var.ssh_username })
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

resource "esxi_guest" "green" {
  for_each = var.nodes_green

  guest_name     = each.key
  disk_store     = var.esxi_datastore
  clone_from_vm  = var.template_green
  boot_disk_type = "thin"
  power          = "on"

  network_interfaces {
    mac_address     = each.value
    nic_type        = "vmxnet3"
    virtual_network = var.esxi_network_name
  }

  provisioner "remote-exec" {
    inline = [ # setting hostname because it's used for Consul and Nomad names
      "sudo hostnamectl set-hostname ${lower(each.key)}",
      "echo '127.0.1.1       ${lower(each.key)}.unassigned-domain        ${lower(each.key)}' | sudo tee -a /etc/hosts",
      "echo ${vault_approle_auth_backend_role_secret_id.wrapped_secret_id[index(local.green_hostnames, each.key)].wrapping_token} >> /home/${var.ssh_username}/secret_id",
      templatefile("${path.module}/setup_castle.tpl", { ssh_username = var.ssh_username })
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

resource "esxi_guest" "nas" {
  guest_name     = lookup(var.node_nas, "name")
  disk_store     = var.esxi_datastore
  clone_from_vm  = var.template_nas
  boot_disk_type = "thin"
  power          = "on"

  lifecycle {
    prevent_destroy = true
  }

  network_interfaces {
    mac_address     = lookup(var.node_nas, "mac_address")
    nic_type        = "vmxnet3"
    virtual_network = var.esxi_network_name
  }

  virtual_disks {
    virtual_disk_id = esxi_virtual_disk.nas_disk1.id
    slot            = "0:1"
  }

  virtual_disks {
    virtual_disk_id = esxi_virtual_disk.nas_disk2.id
    slot            = "0:2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo zpool create -f data mirror /dev/sdb /dev/sdc",
      "echo \"/data    ${var.nas_allow_ip_cidr}(rw,sync,no_root_squash,no_subtree_check)\" | sudo tee -a /etc/exports",
      "sudo systemctl restart nfs-kernel-server"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = self.ip_address
    }
  }
}

resource "esxi_virtual_disk" "nas_disk1" {
  virtual_disk_disk_store = var.esxi_datastore
  virtual_disk_dir        = lookup(var.node_nas, "name")
  virtual_disk_size       = var.nas_disk_size
  virtual_disk_type       = "thin"

  lifecycle {
    prevent_destroy = true
  }
}

resource "esxi_virtual_disk" "nas_disk2" {
  virtual_disk_disk_store = var.esxi_datastore_nas_mirror
  virtual_disk_dir        = lookup(var.node_nas, "name")
  virtual_disk_size       = var.nas_disk_size
  virtual_disk_type       = "thin"

  lifecycle {
    prevent_destroy = true
  }
}

# change this to for_each
resource "esxi_guest" "k3s" {
  guest_name     = lookup(var.node_k3s, "name")
  disk_store     = var.esxi_datastore
  clone_from_vm  = var.template_k3s
  boot_disk_type = "thin"
  power          = "on"

  network_interfaces {
    mac_address     = lookup(var.node_k3s, "mac_address")
    nic_type        = "vmxnet3"
    virtual_network = var.esxi_network_name
  }

  provisioner "remote-exec" {
    inline = [ # this puts the kube config into the user's home directory
      "sudo cp /etc/rancher/k3s/k3s.yaml k3s.yaml; sudo chown ${var.ssh_username}:${var.ssh_username} k3s.yaml"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      private_key = var.ssh_private_key
      host        = esxi_guest.k3s.ip_address
    }
  }
}

# this copies the kube config to the terraform runner
resource "null_resource" "get-k3s-config" {
  depends_on = [esxi_guest.k3s]

  provisioner "local-exec" {
    command = <<EOC
      echo '${var.ssh_private_key}' > private.key; 
      chmod 400 private.key;
      scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i private.key ${var.ssh_username}@${esxi_guest.k3s.ip_address}:k3s.yaml .
   EOC
  }
}

# this provides the kube config as an output
module "k3s-config" {
  depends_on = [null_resource.get-k3s-config]

  source  = "matti/resource/shell"
  command = "cat k3s.yaml"
}

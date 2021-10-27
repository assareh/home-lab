output "ip_addresses_blue" {
  value = { for k, v in esxi_guest.blue : k => v.ip_address }
}

output "ip_addresses_green" {
  value = { for k, v in esxi_guest.green : k => v.ip_address }
}

output "ip_address_k3s" {
  value = esxi_guest.k3s.ip_address
}

output "ip_address_nas" {
  value = esxi_guest.nas.ip_address
}

output "k3s-config" {
  value     = module.k3s-config.stdout
  sensitive = true
}

output "note" {
  value = "It's grabbing the floating VIP addresses instead of the actual node IP."
}
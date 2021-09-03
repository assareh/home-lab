output "ip_addresses_blue" {
  value = { for k, v in esxi_guest.blue : k => v.ip_address }
}

output "ip_addresses_green" {
  value = { for k, v in esxi_guest.green : k => v.ip_address }
}

output "ip_address_moat" {
  value = esxi_guest.moat.ip_address
}

output "ip_address_nas" {
  value = esxi_guest.nas.ip_address
}

output "note" {
  value = "There's something wrong with this output where it's grabbing the floating VIP address."
}
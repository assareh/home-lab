output "ip_addresses_blue" {
  value = { for k, v in esxi_guest.blue : k => v.ip_address }
}

output "ip_addresses_green" {
  value = { for k, v in esxi_guest.green : k => v.ip_address }
}

output "ip_addresses_moat" {
  value = { for k, v in esxi_guest.moat : k => v.ip_address }
}

output "note" {
  value = "There's something wrong with this output where it's grabbing the floating VIP address."
}
output "node_linux_public_ips" {
  description = "ip addresses of the linux nodes"
  value       = "${azurerm_public_ip.computes_linux.*.ip_address}"
}

output "node_linux_private_ips" {
  description = "private ip addresses of the linux nodes"
  value       = "${azurerm_network_interface.computes_linux.*.private_ip_address}"
}

output "node_windows_public_ips" {
  description = "ip addresses of the windows nodes"
  value       = "${azurerm_public_ip.computes_win.*.ip_address}"
}

output "node_windows_private_ips" {
  description = "private ip addresses of the windows nodes"
  value       = "${azurerm_network_interface.computes_win.*.private_ip_address}"
}

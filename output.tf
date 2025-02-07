# Output the VNet details
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnets" {
  value = [azurerm_subnet.frontend.name, azurerm_subnet.backend.name, azurerm_subnet.database.name]
}

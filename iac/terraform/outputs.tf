output "db_ip" {
  value = azurerm_public_ip.db_public_ip.ip_address
}

output "app_url" {
  value = "${azurerm_linux_web_app.parcial2ipti.name}.azurewebsites.net"
}

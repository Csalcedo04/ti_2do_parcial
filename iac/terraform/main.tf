terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    # tls = {
    #   source = "hashicorp/tls"
    #   version = "~>4.0"
    # }
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Configuración general
resource "azurerm_resource_group" "parcial2" {
  name     = "parcial2"
  location = "eastus"
}

resource "azurerm_network_security_group" "parcial2_nsg" {
  name                = "parcial2_nsg"
  location            = azurerm_resource_group.parcial2.location
  resource_group_name = azurerm_resource_group.parcial2.name

  security_rule {
    name                       = "allowSSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowMySQL"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "parcial2_network" {
  name                = "parcial2_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.parcial2.location
  resource_group_name = azurerm_resource_group.parcial2.name
}

resource "azurerm_subnet" "parcial2_subnet" {
  name                 = "parcial2_subnet"
  resource_group_name  = azurerm_resource_group.parcial2.name
  virtual_network_name = azurerm_virtual_network.parcial2_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Configuración App
resource "azurerm_service_plan" "app_asp" {
  name                = "app_asp"
  location            = azurerm_resource_group.parcial2.location
  resource_group_name = azurerm_resource_group.parcial2.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "parcial2ipti" {
  name                  = "parcial2ipti"
  location              = azurerm_resource_group.parcial2.location
  resource_group_name   = azurerm_resource_group.parcial2.name
  service_plan_id       = azurerm_service_plan.app_asp.id
  https_only            = true

  site_config { 
    minimum_tls_version = "1.2"

    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = true
    WEBSITE_NODE_DEFAULT_VERSION ="18-lts"
  }
}

# Configuración DB VM
resource "azurerm_public_ip" "db_public_ip" {
  name                = "db_ip"
  location            = azurerm_resource_group.parcial2.location
  resource_group_name = azurerm_resource_group.parcial2.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "db_nic" {
  name                = "db_nic"
  location            = azurerm_resource_group.parcial2.location
  resource_group_name = azurerm_resource_group.parcial2.name

  ip_configuration {
    name                          = "ipconfig_db_nic"
    subnet_id                     = azurerm_subnet.parcial2_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.db_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc_" {
  network_interface_id      = azurerm_network_interface.db_nic.id
  network_security_group_id = azurerm_network_security_group.parcial2_nsg.id
}

resource "tls_private_key" "db" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "db" {
  content         = tls_private_key.db.private_key_openssh
  filename        = "../secrets/db"
  file_permission = "0600"
}

# Creación db VM
resource "azurerm_linux_virtual_machine" "db" {
  name                  = "db"
  location              = azurerm_resource_group.parcial2.location
  resource_group_name   = azurerm_resource_group.parcial2.name
  network_interface_ids = [azurerm_network_interface.db_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "db_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }

  computer_name                   = var.db_hostname
  admin_username                  = var.username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.db.public_key_openssh
  }

  provisioner "local-exec" {
    command = "./post-apply-script.sh ${var.username} ${var.db_hostname} ${azurerm_public_ip.db_public_ip.ip_address} ${local_sensitive_file.db.filename}"
  }
}


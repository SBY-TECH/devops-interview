resource "azurerm_resource_group" "rg-sby-test" {
  name     = "rg-sby-test"
  location = "East US"
}

#resource "azurerm_service_plan" "asp-sby" {
#  name                = "asp-sby"
#  resource_group_name = azurerm_resource_group.rg-sby-test.name
#  location            = azurerm_resource_group.rg-sby-test.location
#  os_type             = "Linux"
#  sku_name            = "P1v2"
#}

resource "azurerm_network_interface" "nic-sby" {
  name                = "nic-sby"
  location            = azurerm_resource_group.rg-sby-test.location
  resource_group_name = azurerm_resource_group.rg-sby-test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-sby" {
  name                = "vm-sby"
  resource_group_name = azurerm_resource_group.rg-sby-test.name
  location            = azurerm_resource_group.rg-sby-test.location
  size                = "Standard_DS1_v2"
  admin_username      = "RootAdmin"
  admin_password      = "P@ssword"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic-sby.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_virtual_network" "vnet-sby" {
  name                = "sby-network"
  address_space       = ["192.168.1.0/25"]
  location            = azurerm_resource_group.rg-sby-test.location
  resource_group_name = azurerm_resource_group.rg-sby-test.name
}

resource "azurerm_subnet" "internal" {
  name = "internal"
  resource_group_name = azurerm_resource_group.rg-sby-test.name
  virtual_network_name = azurerm_virtual_network.vnet-sby.name
  address_prefixes = ["192.168.1.0/26"]
}

resource "azurerm_postgresql_server" "psql-sby" {
  name                = "sby-psqlserver"
  location            = azurerm_resource_group.rg-sby-test.location
  resource_group_name = azurerm_resource_group.rg-sby-test.name

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

#resource "azurerm_postgresql_virtual_network_rule" "sby-vnet-rule" {
#  name                                 = "postgresql-vnet-rule"
#  resource_group_name                  = azurerm_resource_group.rg-sby-test.name
#  server_name                          = azurerm_postgresql_server.psql-sby.name
#  subnet_id                            = azurerm_subnet.internal.id
#  ignore_missing_vnet_service_endpoint = true
#}
#vnet azure
resource "azurerm_subnet" "app_subnet" {
  name                 = "snet-azgwc-app"
  resource_group_name  = data.azurerm_resource_group.main_rg.name
  virtual_network_name = data.azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.22.1.64/26"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-azgwc-db"
  resource_group_name  = data.azurerm_resource_group.main_rg.name
  virtual_network_name = data.azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.22.1.128/26"]
}

#serverless azure mssql server
resource "azurerm_mssql_server" "sql_server" {
  name                          = "sqlserverazgwc"
  resource_group_name           = data.azurerm_resource_group.main_rg.name
  location                      = "Germany West Central"
  version                       = "12.0"
  administrator_login           = "sqladminuser"
  administrator_login_password  = "P@ssword1234!"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "sql_database" {
  name           = "sqldbazgwc"
  server_id      = azurerm_mssql_server.sql_server.id
  sku_name       = "S0"
  max_size_gb    = 10
  zone_redundant = false
}

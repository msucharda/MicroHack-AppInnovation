#vnet azure
resource "azurerm_subnet" "app_subnet" {
  name                 = "snet-azgwc-app"
  resource_group_name  = data.azurerm_resource_group.main_rg.name
  virtual_network_name = data.azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.22.1.64/26"]

  delegation {
    name = "delegation-to-containerapps"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

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
  sku_name       = "GP_S_Gen5_1"
  max_size_gb    = 10
  zone_redundant = false
}

#private dns zone for mssql

resource "azurerm_private_dns_zone" "mssql_private_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_resource_group.main_rg.name
}

#link vnet to private dns for mssql
resource "azurerm_private_dns_zone_virtual_network_link" "mssql_dns_vnet_link" {
  name                  = "link-mssql-azgwc"
  resource_group_name   = data.azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mssql_private_dns.name
  virtual_network_id    = data.azurerm_virtual_network.main_vnet.id
}

#log analytics workspace
resource "azurerm_log_analytics_workspace" "main_workspace" {
  name                = "law-azgwc"
  location            = "Germany West Central"
  resource_group_name = data.azurerm_resource_group.main_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


#container apps environment deployed to vnet
resource "azurerm_container_app_environment" "main_env" {
  name                = "env-azgwc"
  location            = "Germany West Central"
  resource_group_name = data.azurerm_resource_group.main_rg.name

  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main_workspace.id
  infrastructure_subnet_id   = azurerm_subnet.app_subnet.id
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    maximum_count         = 1
    minimum_count         = 0
  }
}

#azure container registry
resource "azurerm_container_registry" "main_acr" {
  name                          = "acrAzgwc12345"
  resource_group_name           = data.azurerm_resource_group.main_rg.name
  location                      = "Germany West Central"
  sku                           = "Basic"
  admin_enabled                 = true
  public_network_access_enabled = false
}

#private dns for acr
resource "azurerm_private_dns_zone" "acr_private_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.main_rg.name
}

#link vnet to private dns for acr
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_vnet_link" {
  name                  = "link-acr-azgwc"
  resource_group_name   = data.azurerm_resource_group.main_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns.name
  virtual_network_id    = data.azurerm_virtual_network.main_vnet.id
}

#private endpoint for acr
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "pe-acr-azgwc"
  location            = "Germany West Central"
  resource_group_name = data.azurerm_resource_group.main_rg.name
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "psc-acr-azgwc"
    private_connection_resource_id = azurerm_container_registry.main_acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

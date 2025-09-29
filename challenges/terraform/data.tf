data "azurerm_resource_group" "main_rg" {
  name = "rg-user022"
}

data "azurerm_virtual_network" "main_vnet" {
  name                = "vnet-user022"
  resource_group_name = data.azurerm_resource_group.main_rg.name
}

resource "azurerm_resource_group" "identity_resource_group" {
    name = "${var.resourcegroup_prefix}-${var.environment}-identity"
    location = var.location
}

resource "azurerm_container_app_environment" "identity_app_environment" {
    name = "${var.identity_aca}-environment"
    location = azurerm_resource_group.identity_resource_group.location
    resource_group_name = azurerm_resource_group.identity_resource_group.name
}

resource "azurerm_container_app" "identity_app" {
    name                         = var.identity_aca
    container_app_environment_id = azurerm_container_app_environment.identity_app_environment.id
    resource_group_name          = azurerm_resource_group.identity_resource_group.name
    revision_mode                = "Single"

    template {
        container {
        name   = "${var.identity_aca}-cont"
        image  = "mcr.microsoft.com/dotnet/runtime:9.0-noble"
        cpu    = 0.25
        memory = "0.5Gi"
        }
    }
}

resource "azurerm_virtual_network" "identity_app_vnet" {
  name                = "${var.identity_aca}-vnet"
  location            = azurerm_resource_group.identity_resource_group.location
  resource_group_name = azurerm_resource_group.identity_resource_group.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "identity_app_subnet" {
  name                 = "example-sn"
  resource_group_name  = azurerm_resource_group.identity_resource_group.name
  virtual_network_name = azurerm_virtual_network.identity_app_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "identity_app_private_dns_zone" {
  name                = "identity.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.identity_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "identity_app_private_dns_link" {
  name                  = "identityvnet.com"
  private_dns_zone_name = azurerm_private_dns_zone.identity_app_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.identity_app_vnet.id
  resource_group_name   = azurerm_resource_group.identity_resource_group.name
  depends_on            = [azurerm_subnet.identity_app_subnet]
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "${var.identity_aca}-psqlflexibleserver"
  resource_group_name           = azurerm_resource_group.identity_resource_group.name
  location                      = azurerm_resource_group.identity_resource_group.location
  version                       = "12"
  delegated_subnet_id           = azurerm_subnet.identity_app_subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.identity_app_private_dns_zone.id
  public_network_access_enabled = false
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.identity_app_private_dns_link]

}
resource "azurerm_resource_group" "rg" {
  name     = "rg-smartscan-portfolio"
  location = "North Europe"
}

# 1. Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "gb105smartscanstoragev2"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# 2. Azure AI Services (Computer Vision)
resource "azurerm_cognitive_account" "ai_service" {
  name                = "ais-smartscan-gb105"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "ComputerVision"
  sku_name            = "F0" # Darmowa warstwa
}

# 3. Cosmos DB Account (Serverless)
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-smartscan-gb105-new"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "SmartScanDB"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "Analyses"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths = ["/userId"]
}

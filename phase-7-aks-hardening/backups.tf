## CNPG Backup Storage

resource "azurerm_storage_account" "cnpg_backups" {
  name                     = "mercurybackupsjrich"
  resource_group_name      = azurerm_resource_group.aks.name
  location                 = azurerm_resource_group.aks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "customer1" {
  name                  = "customer1"
  storage_account_id    = azurerm_storage_account.cnpg_backups.id
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "customer1" {
  connection_string = azurerm_storage_account.cnpg_backups.primary_connection_string
  container_name    = azurerm_storage_container.customer1.name
  https_only        = true

  # Fixed dates so the SAS token (and the Key Vault secret) does not change on every plan.
  # Renew by editing the expiry before it lapses (about 2 years).
  start  = "2026-10-16T00:00:00Z"
  expiry = "2028-10-16T00:00:00Z"

  permissions {
    read   = true
    write  = true
    delete = true
    list   = true
    add    = true
    create = true
  }
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.cnpg_backups.name
  key_vault_id = azurerm_key_vault.mercury_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "customer1_blob_sas" {
  name         = "customer1-blob-sas"
  value        = data.azurerm_storage_account_blob_container_sas.customer1.sas
  key_vault_id = azurerm_key_vault.mercury_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

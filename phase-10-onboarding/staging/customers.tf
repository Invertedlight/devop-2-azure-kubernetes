## Customer Onboarding (staging)
# Add a customer name to provision: storage container, Key Vault secrets, and the GitOps
# manifests (written into the mercury-gitops working copy; commit and push them afterwards).

locals {
  customers = toset([
    "customer1", # existing customer from Phases 5-9, adopted via moved blocks below
    "julius",
  ])

  environment      = "staging"
  domain           = "jameshomelab.org"
  host_label       = "mercury" # -> <customer>-mercury.jameshomelab.org
  gitops_repo_path = "/workspaces/devops2/phase-5-gitops/mercury-gitops"

  customers_sorted = sort(tolist(local.customers))
}

module "customer" {
  source   = "../modules/customer-onboarding"
  for_each = local.customers

  customer_name = each.key
  environment   = local.environment

  key_vault_id                              = azurerm_key_vault.mercury_vault.id
  storage_account_id                        = azurerm_storage_account.cnpg_backups.id
  storage_account_name                      = azurerm_storage_account.cnpg_backups.name
  storage_account_primary_connection_string = azurerm_storage_account.cnpg_backups.primary_connection_string

  keyvault_name                   = azurerm_key_vault.mercury_vault.name
  keyvault_tenant_id              = data.azurerm_client_config.current.tenant_id
  aks_keyvault_identity_client_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id

  gitops_repo_path = local.gitops_repo_path
  domain           = local.domain
  host_label       = local.host_label

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Adopt customer1's existing resources (created in Phase 6/7 at the root) into the module,
# so Terraform does not destroy the backup container or regenerate the DB password.
moved {
  from = random_password.customer1_db_password
  to   = module.customer["customer1"].random_password.db_password
}
moved {
  from = azurerm_key_vault_secret.customer1_db_user
  to   = module.customer["customer1"].azurerm_key_vault_secret.db_user
}
moved {
  from = azurerm_key_vault_secret.customer1_db_password
  to   = module.customer["customer1"].azurerm_key_vault_secret.db_password
}
moved {
  from = azurerm_key_vault_secret.customer1_blob_sas
  to   = module.customer["customer1"].azurerm_key_vault_secret.blob_sas
}
moved {
  from = azurerm_storage_container.customer1
  to   = module.customer["customer1"].azurerm_storage_container.customer
}

# apps/staging/kustomization.yaml listing every customer
resource "local_file" "staging_kustomization" {
  filename = "${local.gitops_repo_path}/apps/${local.environment}/kustomization.yaml"
  content  = <<-YAML
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    %{for customer in local.customers_sorted~}
      - ${customer}
    %{endfor~}
  YAML

  depends_on = [module.customer]
}

# One PodMonitor per customer database (cnpg_* metrics for the Grafana database alerts).
# Lives under monitoring/configs because the PodMonitor CRD comes from kube-prometheus-stack.
resource "local_file" "cnpg_podmonitors" {
  filename = "${local.gitops_repo_path}/monitoring/configs/${local.environment}/cnpg-podmonitors.yaml"
  content = join("---\n", [for customer in local.customers_sorted : <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      name: ${customer}-db
      namespace: ${customer}
    spec:
      selector:
        matchLabels:
          cnpg.io/cluster: ${customer}-db
          cnpg.io/podRole: instance
      podMetricsEndpoints:
        - port: metrics
  YAML
  ])

  depends_on = [module.customer]
}

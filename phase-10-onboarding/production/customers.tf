## Customer Onboarding (production)
# Add a customer name to provision: storage container, Key Vault secrets, and the GitOps
# manifests (written into the mercury-gitops working copy; commit and push them afterwards).

locals {
  customers = toset([
    "julius",
  ])

  environment      = "production"
  domain           = "jameshomelab.org"
  host_label       = "mercury-prod" # -> <customer>-mercury-prod.jameshomelab.org
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

# apps/production/kustomization.yaml listing every customer
resource "local_file" "production_kustomization" {
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

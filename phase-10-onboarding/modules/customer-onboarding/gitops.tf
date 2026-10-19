# GitOps Manifest Generation
# Renders every Kubernetes manifest for a customer from templates/*.yaml.tftpl into the
# GitOps working copy. Templates (instead of inline heredocs) let the manifests be rendered
# and reviewed with `terraform console` before any apply.

locals {
  customer_path = "${var.gitops_repo_path}/apps/${var.environment}/${var.customer_name}"

  # Single-level hostname so Cloudflare's *.jameshomelab.org edge certificate covers it,
  # e.g. julius-mercury.jameshomelab.org (staging), julius-mercury-prod.jameshomelab.org (production)
  hostname = "${var.customer_name}-${var.host_label}.${var.domain}"

  template_vars = {
    customer_name                   = var.customer_name
    hostname                        = local.hostname
    ingress_class                   = var.ingress_class
    aks_keyvault_identity_client_id = var.aks_keyvault_identity_client_id
    keyvault_name                   = var.keyvault_name
    keyvault_tenant_id              = var.keyvault_tenant_id
    storage_account_name            = var.storage_account_name
    db_instances                    = var.db_instances
    db_storage_size                 = var.db_storage_size
    n8n_storage_size                = var.n8n_storage_size
    n8n_version                     = var.n8n_version
    n8n_memory_request              = var.n8n_memory_request
    n8n_memory_limit                = var.n8n_memory_limit
    n8n_cpu_request                 = var.n8n_cpu_request
    n8n_cpu_limit                   = var.n8n_cpu_limit
  }

  manifests = toset([
    "namespace.yaml",
    "secrets.yaml",
    "configmap.yaml",
    "database.yaml",
    "objectstore.yaml",
    "scheduled-backup.yaml",
    "deployment.yaml",
    "service.yaml",
    "ingress.yaml",
    "network-policy.yaml",
    "storage.yaml",
    "kustomization.yaml",
  ])
}

resource "local_file" "manifest" {
  for_each = local.manifests

  filename = "${local.customer_path}/${each.key}"
  content  = templatefile("${path.module}/templates/${each.key}.tftpl", local.template_vars)
}

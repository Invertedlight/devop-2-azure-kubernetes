terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "be6994fd-99cd-4fae-9caa-9f2693b3db0e"
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  }
}

resource "azurerm_resource_group" "aks" {
  name     = "rg-cloud-course-aks"
  location = "westus2"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "mercury-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "mercury"
  kubernetes_version  = "1.35.0"

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2alds_v6"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "cilium"
    network_data_plane = "cilium"
  }
}

# In-cluster Postgres (Flexible Server is not available on this subscription)
resource "helm_release" "n8n_pg" {
  name             = "n8n-pg"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "postgresql"
  namespace        = "n8n"
  create_namespace = true
  timeout          = 600

  set {
    name  = "auth.username"
    value = "n8nadmin"
  }

  set_sensitive {
    name  = "auth.password"
    value = "N8n-P@ssw0rd"
  }

  set {
    name  = "auth.database"
    value = "n8n"
  }

  set {
    name  = "primary.persistence.size"
    value = "8Gi"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}

output "db_host" {
  value = "n8n-pg-postgresql.n8n.svc.cluster.local"
}

output "db_port" {
  value = 5432
}

output "db_name" {
  value = "n8n"
}

output "db_user" {
  value = "n8nadmin"
}

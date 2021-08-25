resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group}_${var.environment}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "terraform-k8s" {
  name                = "${var.cluster_name}_${var.environment}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = var.dns_prefix

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  provider "azurerm" {
  features {}
  subscription_id = "d09feed3-4053-43d3-900a-cbb8a38db0a5"
  skip_provider_registration = "true"
}

provider "azurerm" {
  features {}
  subscription_id = "d09feed3-4053-43d3-900a-cbb8a38db0a5"
  skip_provider_registration = "true"
  alias  = "shared"
}

module "cluster-addons" {
  source = "./modules/cluster-addons"
  providers = {
    azurerm.shared = azurerm.shared
    azurerm    = azurerm
  }
}

data "azurerm_resource_group" "MCSACRrg" {
  provider = azurerm.shared
  name = var.MCSACRrg
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = data.azurerm_resource_group.MCSACRrg.id
  role_definition_name             = "AcrPull"
  principal_id                     = data.azurerm_kubernetes_cluster.k8s.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}
  
  default_node_pool {
    name            = "agentpool"
    node_count      = var.node_count
    vm_size         = "Standard_DS1_v2"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

    required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.62.0"
      configuration_aliases = [azurerm.mcs, azurerm.shared]
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 1.5.0"
    }
  }
  
  tags = {
    Environment = var.environment
  }
}

terraform {
  backend "azurerm" {
    # storage_account_name="<<storage_account_name>>" #OVERRIDE in TERRAFORM init
    # access_key="<<storage_account_key>>" #OVERRIDE in TERRAFORM init
    # key="<<env_name.k8s.tfstate>>" #OVERRIDE in TERRAFORM init
    # container_name="<<storage_account_container_name>>" #OVERRIDE in TERRAFORM init
  
  }
}

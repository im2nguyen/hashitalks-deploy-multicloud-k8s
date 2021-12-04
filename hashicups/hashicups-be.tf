data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../aks/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

provider "helm" {
  alias = "aks"

  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "product-api-db" {
  provider = helm.aks
  name     = "product-api-db"

  chart = "product-api-db/helm"

  values = [
    "${file("product-api-db/helm/values.yaml")}"
  ]
}

resource "helm_release" "product-api" {
  provider = helm.aks
  name     = "product-api"

  chart = "product-api/helm"

  values = [
    "${file("product-api/helm/values.yaml")}"
  ]
}

resource "helm_release" "payments" {
  provider = helm.aks
  name     = "payments"

  chart = "payments/helm"

  values = [
    "${file("payments/helm/values.yaml")}"
  ]
}

resource "helm_release" "public-api" {
  provider = helm.aks
  name     = "public-api"

  chart = "public-api/helm"

  values = [
    "${file("public-api/helm/values.yaml")}"
  ]
}
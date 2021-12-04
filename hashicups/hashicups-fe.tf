data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../eks/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "helm" {
  alias                  = "eks"

  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
        api_version = "client.authentication.k8s.io/v1alpha1"
        args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
        command     = "aws"
    }
  }
}

resource "helm_release" "frontend" {
  provider = helm.eks
  name     = "frontend"

  chart = "frontend/helm"

  values = [
    "${file("frontend/helm/values.yaml")}"
  ]
}
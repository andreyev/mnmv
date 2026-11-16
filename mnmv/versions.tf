terraform {
  required_version = ">= 1.8.0"

  # O caminho do state é passado pelo script `mnmv` (-backend-config=path=...),
  # para ficar no projeto do usuário e não no cache do código.
  backend "local" {}

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig
}

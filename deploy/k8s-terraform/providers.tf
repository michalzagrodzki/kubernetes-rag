terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.5.1"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}

# (Optional) kubectl provider if you apply raw YAMLs:
provider "kubectl" {
  load_config_file = true
  config_path      = var.kubeconfig_path
  config_context   = var.kubeconfig_context
}

provider "kind" {}

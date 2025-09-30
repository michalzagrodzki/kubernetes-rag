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
  host                   = kind_cluster.rag.endpoint
  client_certificate     = kind_cluster.rag.client_certificate
  client_key             = kind_cluster.rag.client_key
  cluster_ca_certificate = kind_cluster.rag.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.rag.endpoint
    client_certificate     = kind_cluster.rag.client_certificate
    client_key             = kind_cluster.rag.client_key
    cluster_ca_certificate = kind_cluster.rag.cluster_ca_certificate
  }
}

# (Optional) kubectl provider if you apply raw YAMLs:
provider "kubectl" {
  host                   = kind_cluster.rag.endpoint
  client_certificate     = kind_cluster.rag.client_certificate
  client_key             = kind_cluster.rag.client_key
  cluster_ca_certificate = kind_cluster.rag.cluster_ca_certificate
  load_config_file       = false
}

provider "kind" {}

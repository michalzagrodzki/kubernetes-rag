############################
# Namespaces
############################
resource "kubernetes_namespace_v1" "ingress_nginx" { 
  metadata { name = "ingress-nginx" } 
}
resource "kubernetes_namespace_v1" "cert_manager"  { 
  metadata { name = "cert-manager"  } 
}
resource "kubernetes_namespace_v1" "monitoring"    { 
  metadata { name = "monitoring"    } 
}
resource "kubernetes_namespace_v1" "metallb"       { 
  metadata { name = "metallb-system"} 
}
resource "kubernetes_namespace_v1" "rag"           { 
  metadata { name = "rag-dev"       } 
}

############################
# Storage class for kind (local-path) – optional if you already have one
############################
data "kubectl_file_documents" "local_path_sc" {
  content = <<YAML
apiVersion: v1
kind: Namespace
metadata: { name: local-path-storage }
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: local-path-provisioner
  namespace: kube-system
spec:
  chart: https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/chart/local-path-provisioner-0.0.24.tgz
YAML
}
resource "kubectl_manifest" "local_path_sc" {
  for_each  = toset(data.kubectl_file_documents.local_path_sc.documents)
  yaml_body = each.value
}

############################
# Ingress-NGINX
############################
resource "helm_release" "ingress_nginx" {
  name       = "ing"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name

  create_namespace = false

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

############################
# cert-manager (use new CRD flag)
############################
resource "helm_release" "cert_manager" {
  name       = "cert"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name

  create_namespace = false

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# Self-signed ClusterIssuer (dev)
resource "kubectl_manifest" "selfsigned_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
YAML
  depends_on = [helm_release.cert_manager]
}

############################
# Metrics Server
############################
resource "helm_release" "metrics_server" {
  name       = "metrics"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}

############################
# Optional: MetalLB (LoadBalancer on kind)
############################
resource "helm_release" "metallb" {
  name       = "lb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace_v1.metallb.metadata[0].name
}

resource "kubectl_manifest" "metallb_pool" {
  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dev-pool
  namespace: ${kubernetes_namespace_v1.metallb.metadata[0].name}
spec:
  addresses: ["${var.metallb_pool}"]
YAML
  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "metallb_l2" {
  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: dev-adv
  namespace: ${kubernetes_namespace_v1.metallb.metadata[0].name}
spec: {}
YAML
  depends_on = [helm_release.metallb, kubectl_manifest.metallb_pool]
}

############################
# Optional: Cilium (CNI with NetworkPolicies)
############################
resource "helm_release" "cilium" {
  count      = 0 # set to 1 to enable
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  namespace  = "kube-system"

  set { name = "hubble.enabled",       value = "true" }
  set { name = "hubble.relay.enabled", value = "true" }
  set { name = "hubble.ui.enabled",    value = "true" }
}

############################
# App YAMLs: apply your existing manifests from deploy/k8s/
############################
# Recursively pick up all .yaml/.yml in deploy/k8s (namespace, secrets, deployments, services, ingress, etc.)
data "kubectl_path_documents" "app_yamls" {
  pattern = "${path.module}/../deploy/k8s/*.{yaml,yml}"
}

resource "kubectl_manifest" "app" {
  for_each  = toset(data.kubectl_path_documents.app_yamls.documents)
  yaml_body = each.value
  depends_on = [
    helm_release.ingress_nginx,
    helm_release.cert_manager,
    kubectl_manifest.selfsigned_issuer,
    helm_release.metrics_server,
    # If your ingress needs a LoadBalancer Service, also depend on metallb:
    # helm_release.metallb
  ]
}

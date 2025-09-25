resource "kind_cluster" "rag" {
  name = var.kind_cluster_name

  wait_for_ready = true

  kubeconfig_path    = pathexpand(var.kubeconfig_path)
  kubeconfig_context = var.kubeconfig_context

  config = file("${path.module}/../k8s/kind-cluster.yaml")
}

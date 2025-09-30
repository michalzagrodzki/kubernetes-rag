resource "kind_cluster" "rag" {
  name           = var.kind_cluster_name
  wait_for_ready = true

  kubeconfig_path = pathexpand(var.kubeconfig_path)

  kind_config {
    api_version = "kind.x-k8s.io/v1alpha4"
    kind        = "Cluster"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOT
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            enable-admission-plugins: "NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,PodSecurity"
        EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

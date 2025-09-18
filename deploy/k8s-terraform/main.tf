resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "rag_secrets" {
  metadata {
    name      = "rag-secrets"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
  }
  data = {
    POSTGRES_URL     = var.postgres_url
    POSTGRES_SERVER  = var.postgres_server
    POSTGRES_PORT    = tostring(var.postgres_port)
    POSTGRES_USER    = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
    POSTGRES_DB      = var.postgres_db
    EMBEDDING_MODEL  = var.embedding_model
  }
  type = "Opaque"
}

resource "kubernetes_config_map_v1" "rag_config" {
  metadata {
    name      = "rag-config"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
  }
  data = {
    TOP_K           = tostring(var.top_k)
    PDF_DIR         = var.pdf_dir
    CORS_ORIGINS    = var.cors_origins
    # Backend runtime configuration for in-cluster services
    TEI_BASE_URL         = "http://tei:80"
    LOCAL_LLM_BASE_URL   = "http://llm:8000/v1"
    LOCAL_LLM_MODEL      = var.local_llm_model
    LOCAL_LLM_STREAMING  = tostring(var.local_llm_streaming)
  }
}

resource "kubernetes_persistent_volume_claim_v1" "pdfs" {
  metadata {
    name      = "pdfs-pvc"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pdf_storage_size
      }
    }
    storage_class_name = var.storage_class_name
  }
}

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "rag-backend"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "rag-backend"
    }
  }
  spec {
    replicas = var.backend_replicas
    selector {
      match_labels = {
        app = "rag-backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "rag-backend"
        }
      }
      spec {
        container {
          name  = "api"
          image = var.backend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.rag_config.metadata[0].name
            }
          }
          env {
            name  = "POSTGRES_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rag_secrets.metadata[0].name
                key  = "POSTGRES_URL"
              }
            }
          }
          env {
            name  = "EMBEDDING_MODEL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rag_secrets.metadata[0].name
                key  = "EMBEDDING_MODEL"
              }
            }
          }

          liveness_probe {
            http_get {
              path = "/v1/test-db"
              port = 8000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 2
          }
          readiness_probe {
            http_get {
              path = "/v1/test-db"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 2
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              memory = "1Gi"
            }
          }

          volume_mount {
            name       = "pdfs"
            mount_path = var.pdf_dir
          }
        }

        volume {
          name = "pdfs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.pdfs.metadata[0].name
          }
        }

        security_context {
          run_as_non_root = true
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = "rag-backend"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "rag-backend"
    }
  }
  spec {
    selector = {
      app = "rag-backend"
    }
    port {
      name        = "http"
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_deployment_v1" "llm" {
  metadata {
    name      = "llm"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "llm"
    }
  }
  spec {
    replicas = var.llm_replicas
    selector {
      match_labels = {
        app = "llm"
      }
    }
    template {
      metadata {
        labels = {
          app = "llm"
        }
      }
      spec {
        container {
          name  = "llm"
          image = var.llm_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              memory = "4Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "llm" {
  metadata {
    name      = "llm"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "llm"
    }
  }
  spec {
    selector = {
      app = "llm"
    }
    port {
      name        = "http"
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_deployment_v1" "tei" {
  metadata {
    name      = "tei"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "tei"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "tei"
      }
    }
    template {
      metadata {
        labels = {
          app = "tei"
        }
      }
      spec {
        container {
          name  = "tei"
          image = var.tei_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 80
          }

          args = [
            "--model-id", var.tei_model_id
          ]

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              memory = "4Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "tei" {
  metadata {
    name      = "tei"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "tei"
    }
  }
  spec {
    selector = {
      app = "tei"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "rag-frontend"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "rag-frontend"
    }
  }
  spec {
    replicas = var.frontend_replicas
    selector {
      match_labels = {
        app = "rag-frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "rag-frontend"
        }
      }
      spec {
        container {
          name  = "web"
          image = var.frontend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "rag-frontend"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    labels = {
      app = "rag-frontend"
    }
  }
  spec {
    selector = {
      app = "rag-frontend"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "frontend" {
  metadata {
    name      = "rag-frontend"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      host = var.frontend_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.enable_tls && var.tls_secret_name_frontend != null ? [1] : []
      content {
        secret_name = var.tls_secret_name_frontend
        hosts       = [var.frontend_host]
      }
    }
  }
}

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name      = "rag-api"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      host = var.api_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.backend.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.enable_tls && var.tls_secret_name_api != null ? [1] : []
      content {
        secret_name = var.tls_secret_name_api
        hosts       = [var.api_host]
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "backend" {
  metadata {
    name      = "rag-backend-hpa"
    namespace = kubernetes_namespace_v1.ns.metadata[0].name
  }
  spec {
    scale_target_ref {
      kind       = "Deployment"
      name       = kubernetes_deployment_v1.backend.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 2
    max_replicas = 10
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}

output "namespace" {
  value       = kubernetes_namespace_v1.ns.metadata[0].name
  description = "Deployed namespace"
}

output "backend_service" {
  value       = kubernetes_service_v1.backend.metadata[0].name
  description = "Backend service name"
}

output "frontend_service" {
  value       = kubernetes_service_v1.frontend.metadata[0].name
  description = "Frontend service name"
}

output "llm_service" {
  value       = kubernetes_service_v1.llm.metadata[0].name
  description = "Local LLM (llama.cpp) service name"
}

output "tei_service" {
  value       = kubernetes_service_v1.tei.metadata[0].name
  description = "TEI embeddings service name"
}

output "ingress_hosts" {
  value = {
    frontend = var.frontend_host
    api      = var.api_host
  }
  description = "Ingress hostnames"
}

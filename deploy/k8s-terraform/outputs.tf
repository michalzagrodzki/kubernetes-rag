output "ingress_hosts" {
  value = {
    frontend = var.frontend_host
    api      = var.api_host
  }
  description = "Ingress hostnames"
}

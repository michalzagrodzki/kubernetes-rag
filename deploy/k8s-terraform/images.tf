resource "null_resource" "build_and_load_images" {
  # Re-run when Dockerfiles change
  triggers = {
    backend_dockerfile  = filesha1("${path.module}/../containers/Dockerfile.backend")
    frontend_dockerfile = filesha1("${path.module}/../containers/Dockerfile.frontend")
    llm_dockerfile      = filesha1("${path.module}/../containers/Dockerfile.llamacpp")
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
docker build -f ${path.module}/../containers/Dockerfile.backend   -t rag-backend:dev  --platform linux/arm64 ${path.module}/../..
docker build -f ${path.module}/../containers/Dockerfile.frontend  -t rag-frontend:dev --platform linux/arm64 ${path.module}/../..
docker build -f ${path.module}/../containers/Dockerfile.llamacpp  -t rag-llm:dev      --platform linux/arm64 ${path.module}/../..
kind load docker-image rag-backend:dev  --name ${var.kind_cluster_name}
kind load docker-image rag-frontend:dev --name ${var.kind_cluster_name}
kind load docker-image rag-llm:dev      --name ${var.kind_cluster_name}
EOT
  }

  depends_on = [kind_cluster.rag]
}

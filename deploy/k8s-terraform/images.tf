resource "null_resource" "build_and_load_images" {
  # Re-run when Dockerfiles change
  triggers = {
    backend_dockerfile  = filesha1("${path.module}/../deploy/containers/Dockerfile.backend")
    frontend_dockerfile = filesha1("${path.module}/../deploy/containers/Dockerfile.frontend")
    llm_dockerfile      = filesha1("${path.module}/../deploy/containers/Dockerfile.llamacpp")
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
docker build -f ${path.module}/../deploy/containers/Dockerfile.backend   -t rag-backend:dev  --platform linux/arm64 ${path.module}/..
docker build -f ${path.module}/../deploy/containers/Dockerfile.frontend  -t rag-frontend:dev --platform linux/arm64 ${path.module}/..
docker build -f ${path.module}/../deploy/containers/Dockerfile.llamacpp  -t rag-llm:dev      --platform linux/arm64 ${path.module}/..
kind load docker-image rag-backend:dev  --name rag-dev
kind load docker-image rag-frontend:dev --name rag-dev
kind load docker-image rag-llm:dev      --name rag-dev
EOT
  }
}

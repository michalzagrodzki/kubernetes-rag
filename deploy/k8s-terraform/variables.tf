variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "kubectl context to use"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "rag-web"
}

variable "backend_image" {
  description = "Full image ref for backend"
  type        = string
  default     = "rag-backend:dev"
}

variable "frontend_image" {
  description = "Full image ref for frontend"
  type        = string
  default     = "rag-frontend:dev"
}

variable "llm_image" {
  description = "Image for local LLM (llama.cpp based)"
  type        = string
  default     = "rag-llm:qwen2.5-1.5b"
}

variable "local_llm_model" {
  description = "Model id/name for local LLM server"
  type        = string
  default     = "qwen2.5-1.5b-instruct"
}

variable "local_llm_streaming" {
  description = "Enable upstream streaming from local LLM"
  type        = bool
  default     = false
}

variable "tei_image" {
  description = "Image for text-embeddings-inference (TEI)"
  type        = string
  default     = "ghcr.io/huggingface/text-embeddings-inference:cpu-1.8"
}

variable "tei_model_id" {
  description = "Model id/path for TEI (e.g., nomic-ai/nomic-embed-text-v1.5)"
  type        = string
  default     = "nomic-ai/nomic-embed-text-v1.5"
}

variable "frontend_host" {
  description = "Hostname for frontend ingress (e.g., app.example.com)"
  type        = string
}

variable "api_host" {
  description = "Hostname for API ingress (e.g., api.example.com)"
  type        = string
}

variable "enable_tls" {
  description = "Enable TLS on Ingress"
  type        = bool
  default     = false
}

variable "tls_secret_name_frontend" {
  description = "TLS secret name for frontend host"
  type        = string
  default     = null
}

variable "tls_secret_name_api" {
  description = "TLS secret name for API host"
  type        = string
  default     = null
}

variable "backend_replicas" {
  type    = number
  default = 2
}

variable "frontend_replicas" {
  type    = number
  default = 2
}

variable "llm_replicas" {
  description = "Replicas for local LLM server"
  type        = number
  default     = 1
}

variable "storage_class_name" {
  description = "StorageClass for PDF PVC"
  type        = string
  default     = null
}

variable "pdf_storage_size" {
  description = "Size for PDF PVC"
  type        = string
  default     = "10Gi"
}

variable "cors_origins" {
  description = "Comma-separated allowed CORS origins"
  type        = string
  default     = "http://localhost:5173"
}

variable "pdf_dir" {
  description = "PDF directory in container"
  type        = string
  default     = "/app/pdfs"
}

variable "postgres_url" {
  type        = string
  description = "Postgres connection URL (asyncpg)"
  sensitive   = true
}

variable "postgres_server" {
  type        = string
  description = "Postgres server hostname"
}

variable "postgres_port" {
  type        = number
  description = "Postgres server port"
  default     = 6543
}

variable "postgres_user" {
  type        = string
  description = "Postgres username"
}

variable "postgres_password" {
  type        = string
  description = "Postgres password"
  sensitive   = true
}

variable "postgres_db" {
  type        = string
  description = "Postgres database name"
}

variable "embedding_model" {
  type        = string
  description = "Embedding model"
  default     = "text-embedding-3-small"
}

variable "top_k" {
  type        = number
  description = "Top K documents to retrieve"
  default     = 5
}

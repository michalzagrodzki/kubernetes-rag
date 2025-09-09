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
  default     = "ghcr.io/example/rag-backend:latest"
}

variable "frontend_image" {
  description = "Full image ref for frontend"
  type        = string
  default     = "ghcr.io/example/rag-frontend:latest"
}

variable "vllm_image" {
  description = "Image for vLLM OpenAI server"
  type        = string
  default     = "vllm/vllm-openai:latest"
}

variable "vllm_model" {
  description = "HuggingFace model id for vLLM"
  type        = string
  default     = "meta-llama/Llama-3.1-8B-Instruct"
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

variable "vllm_replicas" {
  type    = number
  default = 1
}

variable "vllm_gpu_count" {
  description = "Number of GPUs per vLLM pod"
  type        = number
  default     = 1
}

variable "vllm_tensor_parallel_size" {
  description = "Tensor parallel size for vLLM"
  type        = number
  default     = 1
}

variable "vllm_node_selector" {
  description = "Node selector for vLLM pods"
  type        = map(string)
  default     = {}
}

variable "vllm_tolerations" {
  description = "Tolerations for vLLM pods"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
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

variable "supabase_url" {
  type        = string
  description = "Supabase project URL"
}

variable "supabase_key" {
  type        = string
  description = "Supabase API key"
  sensitive   = true
}

variable "supabase_table" {
  type        = string
  description = "Supabase table for vectors"
  default     = "documents"
}

variable "postgres_url" {
  type        = string
  description = "Postgres connection URL (asyncpg)"
  sensitive   = true
}

variable "openai_api_key" {
  type        = string
  description = "OpenAI API key (or dummy when using vLLM)"
  sensitive   = true
}

variable "openai_model" {
  type        = string
  description = "Default chat model"
  default     = "gpt-3.5-turbo"
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


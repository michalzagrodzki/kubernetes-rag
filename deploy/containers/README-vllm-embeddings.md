vLLM Embeddings Image (Qwen3-Embedding-8B)

This Dockerfile runs the vLLM OpenAI-compatible server hosting the Qwen/Qwen3-Embedding-8B model and serving the /v1/embeddings endpoint.

Highlights
- Non-root runtime user; writable cache at /data/hf-cache
- OpenAI-compatible API via vLLM, optimized for GPU usage
- Healthcheck for /v1/models
- Optional prefetch of model weights at startup (PREFETCH=1)

Build
docker build -f deploy/containers/Dockerfile.vllm-embeddings -t <registry>/vllm-embeddings:qwen3-8b .

Run (Docker)
docker run --rm \
  --gpus all \
  --env HF_TOKEN=$HF_TOKEN \
  -e MODEL_ID=Qwen/Qwen3-Embedding-8B \
  -e TENSOR_PARALLEL=1 \
  -e GPU_MEM_UTIL=0.90 \
  -e MAX_MODEL_LEN=8192 \
  -e PREFETCH=1 \
  -p 8000:8000 \
  -v qwen-hf-cache:/data/hf-cache \
  <registry>/vllm-embeddings:qwen3-8b

Notes
- Qwen/Qwen3-Embedding-8B may require accepting a license and using an HF token (set HF_TOKEN env). Consider mounting read-only model volumes in production.
- Use a sufficiently large GPU (24–40GB VRAM recommended). Lower VRAM cards may require quantization (not covered here) or smaller batch sizes.
- The server exposes OpenAI /v1/embeddings and /v1/models endpoints. Example request:

curl -s http://localhost:8000/v1/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"input": ["hello world"], "model": "Qwen/Qwen3-Embedding-8B"}' | jq

Kubernetes Tips
- Request a GPU in the Deployment (e.g., nvidia.com/gpu: 1) and mount a PersistentVolume at /data/hf-cache for warm cache.
- Run as non-root with readOnlyRootFilesystem: true and drop capabilities.
- Set env HF_TOKEN via a Kubernetes Secret if the model requires authorization.

Environment Variables
- MODEL_ID: default Qwen/Qwen3-Embedding-8B
- HOST, PORT: binding address/port (default 0.0.0.0:8000)
- TENSOR_PARALLEL: number of GPUs for tensor parallelism (default 1)
- GPU_MEM_UTIL: fraction of GPU memory to use (default 0.9)
- MAX_MODEL_LEN: context length (default 8192)
- PREFETCH: set 1 to snapshot model weights into cache on startup
- HF_HOME/TRANSFORMERS_CACHE: cache directory (/data/hf-cache)


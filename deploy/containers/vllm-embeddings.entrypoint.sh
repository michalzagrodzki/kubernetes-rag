#!/usr/bin/env bash
set -Eeuo pipefail

# Defaults come from Dockerfile envs; allow override via env at runtime.
MODEL_ID=${MODEL_ID:-Qwen/Qwen3-Embedding-8B}
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8000}
TENSOR_PARALLEL=${TENSOR_PARALLEL:-1}
GPU_MEM_UTIL=${GPU_MEM_UTIL:-0.9}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-8192}
PREFETCH=${PREFETCH:-0}

echo "[vLLM-emb] Starting with model=$MODEL_ID tp=$TENSOR_PARALLEL gpu_mem_util=$GPU_MEM_UTIL max_len=$MAX_MODEL_LEN"

# Ensure cache directory is writable
mkdir -p "${HF_HOME:-/data/hf-cache}"

if [[ "$PREFETCH" == "1" ]]; then
  echo "[vLLM-emb] Prefetching model weights to HF cache..."
  python - <<'PY'
import os
from huggingface_hub import snapshot_download
model_id = os.environ.get('MODEL_ID', 'Qwen/Qwen3-Embedding-8B')
snapshot_download(model_id, local_files_only=False, ignore_patterns=["*.safetensors.index.json"])  # fetch all shards
print("[vLLM-emb] Prefetch complete")
PY
fi

exec python -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_ID" \
  --host "$HOST" \
  --port "$PORT" \
  --tensor-parallel-size "$TENSOR_PARALLEL" \
  --gpu-memory-utilization "$GPU_MEM_UTIL" \
  --max-model-len "$MAX_MODEL_LEN" \
  --disable-log-requests


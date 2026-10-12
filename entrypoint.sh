#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
    exec /opt/llama.cpp/build/bin/llama-server \
        --model /models/nomic-embed-text-v1.5.Q8_0.gguf \
        --alias nomic-embed-text-v1.5 \
        --host 0.0.0.0 --port 8080 \
        --n-gpu-layers "${GPU_LAYERS:-99}" \
        --ctx-size "${CTX_SIZE:-2048}" \
        --parallel "${PARALLEL:-1}" \
        --threads "${THREADS:-8}" \
        --batch-size "${BATCH_SIZE:-2048}" \
        --ubatch-size "${UBATCH_SIZE:-512}" \
        --pooling mean --embedding
fi

exec /opt/llama.cpp/build/bin/llama-server "$@"

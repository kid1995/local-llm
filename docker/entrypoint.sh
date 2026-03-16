#!/bin/bash
# ============================================================
# entrypoint.sh -- Ollama init with model pull and config
# ============================================================
# This script:
#   1. Starts the Ollama server
#   2. Waits for it to be ready
#   3. Pulls the configured LLM and embedding models
#   4. Creates a custom model with configured parameters
#   5. Keeps the server running
# ============================================================

set -euo pipefail

# --- Config from environment (defaults match .env) ---
LLM_MODEL="${LLM_MODEL:-qwen2.5-coder:7b}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text}"
NUM_CTX="${NUM_CTX:-4096}"
TEMPERATURE="${TEMPERATURE:-0.2}"
TOP_P="${TOP_P:-0.9}"
MAX_LOADED_MODELS="${MAX_LOADED_MODELS:-1}"
KEEP_ALIVE="${KEEP_ALIVE:-10m}"

echo "============================================"
echo "  Local LLM Stack -- Initializing"
echo "============================================"
echo "  LLM Model:       $LLM_MODEL"
echo "  Embedding Model:  $EMBEDDING_MODEL"
echo "  Context Window:   $NUM_CTX tokens"
echo "  Temperature:      $TEMPERATURE"
echo "  Max Loaded:       $MAX_LOADED_MODELS"
echo "============================================"

# --- Export Ollama config ---
export OLLAMA_MAX_LOADED_MODELS="$MAX_LOADED_MODELS"
export OLLAMA_KEEP_ALIVE="$KEEP_ALIVE"
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_HOST="0.0.0.0:11434"

# --- Start Ollama server in background ---
echo "[1/5] Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# --- Wait for server to be ready ---
echo "[2/5] Waiting for Ollama to be ready..."
MAX_RETRIES=30
RETRY=0
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "ERROR: Ollama failed to start after ${MAX_RETRIES}s"
        exit 1
    fi
    sleep 1
done
echo "  Ollama is ready."

# --- Pull models ---
echo "[3/5] Pulling LLM model: $LLM_MODEL ..."
ollama pull "$LLM_MODEL"
echo "  Done."

echo "[4/5] Pulling embedding model: $EMBEDDING_MODEL ..."
ollama pull "$EMBEDDING_MODEL"
echo "  Done."

# --- Create custom model with configured parameters ---
echo "[5/5] Creating configured model: local-llm ..."
MODELFILE="/tmp/Modelfile.configured"
cat > "$MODELFILE" << EOF
FROM $LLM_MODEL
PARAMETER temperature $TEMPERATURE
PARAMETER top_p $TOP_P
PARAMETER num_ctx $NUM_CTX
EOF

ollama create local-llm -f "$MODELFILE"
echo "  Custom model 'local-llm' created."

echo ""
echo "============================================"
echo "  Ready!"
echo "============================================"
echo "  API:    http://localhost:11434"
echo "  Models: $LLM_MODEL (also available as 'local-llm')"
echo "          $EMBEDDING_MODEL"
echo ""
echo "  Connect from host:"
echo "    Cline:  http://localhost:${OLLAMA_PORT:-11434}"
echo "    Aider:  aider --model ollama_chat/$LLM_MODEL"
echo "============================================"

# --- Keep the server running ---
wait $OLLAMA_PID

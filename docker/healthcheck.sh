#!/bin/bash
# ============================================================
# healthcheck.sh -- Verify the stack is working correctly
# ============================================================
# Run after docker compose up to verify everything works.
#
# Usage:
#   ./healthcheck.sh                  # Check default port
#   ./healthcheck.sh 11434            # Check specific port
# ============================================================

set -euo pipefail

PORT="${1:-11434}"
BASE_URL="http://localhost:$PORT"
PASS=0
FAIL=0

check() {
    local name="$1"
    local result="$2"
    if [ "$result" = "OK" ]; then
        echo "  PASS  $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name -- $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================"
echo "  Health Check: localhost:$PORT"
echo "============================================"
echo ""

# 1. Server reachable
if curl -sf "$BASE_URL/api/tags" > /dev/null 2>&1; then
    check "Ollama server reachable" "OK"
else
    check "Ollama server reachable" "Cannot connect to $BASE_URL"
    echo ""
    echo "Server not running. Start with: docker compose up -d"
    exit 1
fi

# 2. LLM model available
LLM_MODEL=$(curl -sf "$BASE_URL/api/tags" | python3 -c "
import sys, json
tags = json.load(sys.stdin)
models = [m['name'] for m in tags.get('models', [])]
# Check for any qwen model or local-llm
found = [m for m in models if 'qwen' in m or 'local-llm' in m]
print(found[0] if found else 'NONE')
" 2>/dev/null || echo "NONE")

if [ "$LLM_MODEL" != "NONE" ]; then
    check "LLM model loaded ($LLM_MODEL)" "OK"
else
    check "LLM model loaded" "No Qwen model found"
fi

# 3. Embedding model available
EMBED_MODEL=$(curl -sf "$BASE_URL/api/tags" | python3 -c "
import sys, json
tags = json.load(sys.stdin)
models = [m['name'] for m in tags.get('models', [])]
found = [m for m in models if 'nomic' in m or 'embed' in m]
print(found[0] if found else 'NONE')
" 2>/dev/null || echo "NONE")

if [ "$EMBED_MODEL" != "NONE" ]; then
    check "Embedding model loaded ($EMBED_MODEL)" "OK"
else
    check "Embedding model loaded" "No embedding model found"
fi

# 4. Inference works
RESPONSE=$(curl -sf "$BASE_URL/api/chat" \
    -d "{\"model\": \"$LLM_MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"Say OK\"}], \"stream\": false}" 2>/dev/null \
    | python3 -c "import sys, json; print(json.load(sys.stdin).get('message', {}).get('content', 'EMPTY')[:50])" 2>/dev/null \
    || echo "FAILED")

if [ "$RESPONSE" != "FAILED" ] && [ "$RESPONSE" != "EMPTY" ]; then
    check "Inference working" "OK"
else
    check "Inference working" "Model did not respond"
fi

# 5. Embeddings work
EMBED_RESPONSE=$(curl -sf "$BASE_URL/api/embed" \
    -d "{\"model\": \"$EMBED_MODEL\", \"input\": \"test\"}" 2>/dev/null \
    | python3 -c "import sys, json; e=json.load(sys.stdin).get('embeddings',[]); print(len(e[0]) if e else 0)" 2>/dev/null \
    || echo "0")

if [ "$EMBED_RESPONSE" != "0" ]; then
    check "Embeddings working (${EMBED_RESPONSE} dimensions)" "OK"
else
    check "Embeddings working" "Embedding model did not respond"
fi

# 6. OpenAI-compatible endpoint
COMPAT=$(curl -sf "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"$LLM_MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"Hi\"}]}" 2>/dev/null \
    | python3 -c "import sys, json; print('OK' if json.load(sys.stdin).get('choices') else 'FAIL')" 2>/dev/null \
    || echo "FAIL")

check "OpenAI-compatible API (/v1/chat/completions)" "$COMPAT"

# 7. No external connections
EXTERNAL=$(lsof -i -n -P 2>/dev/null | grep ollama | grep -v "127.0.0.1\|localhost\|\[::1\]\|:$PORT" | head -1 || true)
if [ -z "$EXTERNAL" ]; then
    check "No external network connections" "OK"
else
    check "No external network connections" "Found: $EXTERNAL"
fi

echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "============================================"

exit "$FAIL"

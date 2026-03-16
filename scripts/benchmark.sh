#!/bin/bash
# benchmark.sh
# Benchmarks local LLM performance (tokens/sec, latency, RAM usage)
#
# Usage:
#   ./scripts/benchmark.sh                    # Benchmark default model
#   ./scripts/benchmark.sh qwen2.5-coder:14b  # Benchmark specific model

set -euo pipefail

MODEL="${1:-qwen2.5-coder:7b}"
OLLAMA_URL="http://localhost:11434"

echo "============================================"
echo "  LLM Benchmark: $MODEL"
echo "============================================"
echo ""

# Check if Ollama is running
if ! curl -s "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running. Start with: ollama serve"
    exit 1
fi

# Check if model is available
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "ERROR: Model '$MODEL' not found. Pull with: ollama pull $MODEL"
    exit 1
fi

echo "--- Test 1: Simple Code Generation ---"
RESULT=$(curl -s "$OLLAMA_URL/api/chat" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Write a Python hello world program\"}],
        \"stream\": false
    }")

python3 -c "
import json, sys
d = json.loads('''$RESULT''')
prompt_ns = d.get('prompt_eval_duration', 0)
eval_ns = d.get('eval_duration', 0)
eval_count = d.get('eval_count', 0)
prompt_count = d.get('prompt_eval_count', 0)
total_ns = d.get('total_duration', 0)

print(f'  Prompt tokens:     {prompt_count}')
print(f'  Generated tokens:  {eval_count}')
print(f'  Total time:        {total_ns/1e9:.2f}s')
if prompt_ns > 0:
    print(f'  Time to first tok: {prompt_ns/1e9:.2f}s')
if eval_ns > 0 and eval_count > 0:
    tps = eval_count / (eval_ns / 1e9)
    print(f'  Generation speed:  {tps:.1f} tokens/sec')
" 2>/dev/null || echo "  (Could not parse response)"

echo ""
echo "--- Test 2: Medium Complexity ---"
RESULT2=$(curl -s "$OLLAMA_URL/api/chat" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Write a Python function that implements binary search on a sorted list. Include type hints, docstring, and handle edge cases.\"}],
        \"stream\": false
    }")

python3 -c "
import json, sys
d = json.loads('''$RESULT2''')
eval_ns = d.get('eval_duration', 0)
eval_count = d.get('eval_count', 0)
total_ns = d.get('total_duration', 0)

print(f'  Generated tokens:  {eval_count}')
print(f'  Total time:        {total_ns/1e9:.2f}s')
if eval_ns > 0 and eval_count > 0:
    tps = eval_count / (eval_ns / 1e9)
    print(f'  Generation speed:  {tps:.1f} tokens/sec')
" 2>/dev/null || echo "  (Could not parse response)"

echo ""
echo "--- Test 3: RAM Usage ---"
OLLAMA_PID=$(pgrep -x ollama 2>/dev/null || echo "")
if [ -n "$OLLAMA_PID" ]; then
    RAM_KB=$(ps -o rss= -p "$OLLAMA_PID" 2>/dev/null || echo "0")
    RAM_MB=$((RAM_KB / 1024))
    echo "  Ollama process RAM: ${RAM_MB} MB"
else
    echo "  (Could not find Ollama process)"
fi

# System RAM
echo ""
echo "--- System Memory ---"
if command -v vm_stat &>/dev/null; then
    # macOS
    PAGE_SIZE=$(sysctl -n hw.pagesize)
    FREE_PAGES=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    INACTIVE_PAGES=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    TOTAL_MEM=$(sysctl -n hw.memsize)
    TOTAL_GB=$((TOTAL_MEM / 1073741824))
    FREE_MB=$(( (FREE_PAGES + INACTIVE_PAGES) * PAGE_SIZE / 1048576 ))
    echo "  Total RAM:     ${TOTAL_GB} GB"
    echo "  Available RAM: ~${FREE_MB} MB"
fi

echo ""
echo "============================================"
echo "  Benchmark complete"
echo "============================================"

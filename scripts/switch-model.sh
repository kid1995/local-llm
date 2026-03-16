#!/bin/bash
# switch-model.sh
# Quick model switching with validation
#
# Usage:
#   ./scripts/switch-model.sh qwen2.5-coder:14b
#   ./scripts/switch-model.sh qwen3.5:27b

set -euo pipefail

NEW_MODEL="${1:?Usage: switch-model.sh <model-tag>}"

echo "============================================"
echo "  Model Switch: $NEW_MODEL"
echo "============================================"
echo ""

# 1. Check Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running. Start with: ollama serve"
    exit 1
fi

# 2. Pull model (downloads if needed, no-op if already present)
echo "Step 1: Pulling model (this may take a while on first run)..."
ollama pull "$NEW_MODEL"
echo ""

# 3. Quick test
echo "Step 2: Testing model..."
RESPONSE=$(ollama run "$NEW_MODEL" "Respond with exactly: MODEL_OK" 2>&1 | head -5)
echo "  Response: $RESPONSE"
echo ""

# 4. Update Aider config
AIDER_CONF=".aider.conf.yml"
echo "Step 3: Updating configurations..."

if [ -f "$AIDER_CONF" ]; then
    if grep -q "^model:" "$AIDER_CONF"; then
        sed -i '' "s|^model:.*|model: ollama_chat/$NEW_MODEL|" "$AIDER_CONF"
    else
        echo "model: ollama_chat/$NEW_MODEL" >> "$AIDER_CONF"
    fi
    echo "  Updated: $AIDER_CONF"
else
    cat > "$AIDER_CONF" << EOF
model: ollama_chat/$NEW_MODEL
auto-commits: true
stream: true
pretty: true
EOF
    echo "  Created: $AIDER_CONF"
fi

# 5. Show current models
echo ""
echo "Step 4: Installed models:"
ollama list
echo ""

# 6. Instructions for Cline
echo "============================================"
echo "  Next Steps"
echo "============================================"
echo ""
echo "  Aider: Configuration updated automatically."
echo "         Start with: aider"
echo ""
echo "  Cline: Open VS Code -> Cline Settings"
echo "         Change Model to: $NEW_MODEL"
echo ""
echo "  To remove old models and free disk space:"
echo "         ollama rm <old-model-tag>"
echo ""

#!/bin/bash
# network-monitor.sh
# Monitors network connections from Ollama, VS Code, and Aider
# to prove no data leaves the device.
#
# Usage:
#   ./scripts/network-monitor.sh start    # Start monitoring (background)
#   ./scripts/network-monitor.sh stop     # Stop and show report
#   ./scripts/network-monitor.sh check    # One-time snapshot

set -euo pipefail

LOG_DIR="/tmp/local-llm-monitor"
LOG_FILE="$LOG_DIR/connections.log"
PID_FILE="$LOG_DIR/monitor.pid"

mkdir -p "$LOG_DIR"

check_connections() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== $timestamp ===" >> "$LOG_FILE"

    # Ollama connections
    echo "--- Ollama ---" >> "$LOG_FILE"
    lsof -i -n -P 2>/dev/null | grep -i ollama >> "$LOG_FILE" 2>/dev/null || echo "  (no connections)" >> "$LOG_FILE"

    # VS Code connections (filter for non-localhost)
    echo "--- VS Code (non-localhost only) ---" >> "$LOG_FILE"
    lsof -i -n -P 2>/dev/null | grep -i "code\|electron" | grep -v "127.0.0.1\|localhost\|\[::1\]" >> "$LOG_FILE" 2>/dev/null || echo "  (no external connections)" >> "$LOG_FILE"

    # Aider/Python connections
    echo "--- Aider/Python ---" >> "$LOG_FILE"
    lsof -i -n -P 2>/dev/null | grep -i "python\|aider" >> "$LOG_FILE" 2>/dev/null || echo "  (no connections)" >> "$LOG_FILE"

    echo "" >> "$LOG_FILE"
}

analyze_log() {
    echo "============================================"
    echo "  Network Monitor Report"
    echo "============================================"
    echo ""

    if [ ! -f "$LOG_FILE" ]; then
        echo "No log file found. Run 'start' first."
        exit 1
    fi

    echo "Log file: $LOG_FILE"
    echo "Samples: $(grep -c "^===" "$LOG_FILE" 2>/dev/null || echo 0)"
    echo ""

    # Check for external connections from Ollama
    echo "--- Ollama External Connections ---"
    local ollama_external
    ollama_external=$(grep -A1 "Ollama" "$LOG_FILE" | grep -v "127.0.0.1\|localhost\|\[::1\]\|---\|no conn" | grep -v "^$" || true)
    if [ -z "$ollama_external" ]; then
        echo "  PASS: No external connections detected"
    else
        echo "  WARNING: External connections found:"
        echo "$ollama_external"
    fi

    echo ""
    echo "--- Aider/Python External Connections ---"
    local aider_external
    aider_external=$(grep -A1 "Aider" "$LOG_FILE" | grep -v "127.0.0.1\|localhost\|\[::1\]\|---\|no conn" | grep -v "^$" || true)
    if [ -z "$aider_external" ]; then
        echo "  PASS: No external connections detected"
    else
        echo "  WARNING: External connections found:"
        echo "$aider_external"
    fi

    echo ""
    echo "============================================"
    echo "  Verdict"
    echo "============================================"
    if [ -z "$ollama_external" ] && [ -z "$aider_external" ]; then
        echo "  ALL CLEAR: No external network traffic detected."
        echo "  Data stays on this device."
    else
        echo "  REVIEW NEEDED: Some external connections were found."
        echo "  Check the log for details: $LOG_FILE"
    fi
}

case "${1:-check}" in
    start)
        echo "Starting network monitor (every 5 seconds)..."
        echo "Log: $LOG_FILE"
        > "$LOG_FILE"  # Clear log

        # Run in background
        (
            while true; do
                check_connections
                sleep 5
            done
        ) &
        echo $! > "$PID_FILE"
        echo "Monitor PID: $(cat "$PID_FILE")"
        echo "Run your coding session, then: $0 stop"
        ;;

    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null || true
            rm "$PID_FILE"
            echo "Monitor stopped."
        else
            echo "No running monitor found."
        fi
        echo ""
        analyze_log
        ;;

    check)
        echo "One-time connection check:"
        echo ""
        echo "--- Ollama ---"
        lsof -i -n -P 2>/dev/null | grep -i ollama || echo "  (not running or no connections)"
        echo ""
        echo "--- VS Code / Cline ---"
        lsof -i -n -P 2>/dev/null | grep -i "code\|electron" | grep -v "127.0.0.1\|localhost" | head -20 || echo "  (no external connections)"
        echo ""
        echo "--- Python / Aider ---"
        lsof -i -n -P 2>/dev/null | grep -i "python\|aider" || echo "  (not running or no connections)"
        ;;

    *)
        echo "Usage: $0 {start|stop|check}"
        exit 1
        ;;
esac

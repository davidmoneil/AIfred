#!/bin/bash
# Session Start Hook - Official Claude Code Format
# Fires on: startup, resume, clear, compact

# Read input from stdin (JSON)
INPUT=$(cat)

# Parse source from input
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to diagnostic file
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
echo "$TIMESTAMP | SessionStart | source=$SOURCE | session=$SESSION_ID" >> "$LOG_DIR/session-start-diagnostic.log"

# Check for checkpoint file
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [ -f "$CHECKPOINT_FILE" ]; then
    # Checkpoint exists - output it for context injection
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     🔄 SOFT RESTART ($SOURCE) - CHECKPOINT LOADED            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📦 Source: $SOURCE"
    echo ""
    echo "─────────────────── Checkpoint Context ───────────────────"
    echo ""
    cat "$CHECKPOINT_FILE"
    echo ""
    echo "─────────────────── Instructions ───────────────────"
    echo ""
    echo "   ✅ Checkpoint loaded"
    echo "   📝 Say 'continue' or describe what to do next"
    echo ""
    echo "══════════════════════════════════════════════════════════════"

    # Clear checkpoint after loading (one-time use)
    rm "$CHECKPOINT_FILE"
else
    # No checkpoint - show minimal banner for clear, or normal for startup
    if [ "$SOURCE" = "clear" ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║               CONVERSATION CLEARED                           ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "   💡 No checkpoint found - starting fresh"
        echo "   💡 Use /soft-restart before /clear to preserve context"
        echo ""
    fi
fi

# Exit success
exit 0

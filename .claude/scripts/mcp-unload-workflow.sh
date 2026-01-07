#!/bin/bash
# MCP Unload Workflow Script
# Purpose: Prepare for context-saving restart with MCP reduction
#
# Usage:
#   ./mcp-unload-workflow.sh [mode] [checkpoint_content]
#
# Modes:
#   tier1-only     - Keep only Tier 1 MCPs (memory, filesystem, fetch, git)
#   keep-github    - Keep Tier 1 + github
#   keep-context7  - Keep Tier 1 + context7
#   custom         - Read MCP list from stdin
#
# This script:
#   1. Creates checkpoint file with provided context
#   2. Removes specified MCPs from config
#   3. Outputs instructions for restart

set -e

MODE="${1:-tier1-only}"
CHECKPOINT_CONTENT="${2:-}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
CHECKPOINT_FILE="$PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"
LOG_FILE="$PROJECT_DIR/.claude/logs/mcp-unload-workflow.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Tier 2 MCPs (candidates for removal)
TIER2_MCPS=("time" "context7" "sequential-thinking" "github")

# Log function
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$TIMESTAMP | $1" >> "$LOG_FILE"
}

log "Starting MCP unload workflow - mode: $MODE"

# Determine which MCPs to drop based on mode
case "$MODE" in
    tier1-only)
        DROP_MCPS=("time" "context7" "sequential-thinking" "github")
        KEEP_MCPS=()
        ;;
    keep-github)
        DROP_MCPS=("time" "context7" "sequential-thinking")
        KEEP_MCPS=("github")
        ;;
    keep-context7)
        DROP_MCPS=("time" "github" "sequential-thinking")
        KEEP_MCPS=("context7")
        ;;
    custom)
        # Read custom list from stdin (comma-separated)
        read -r CUSTOM_DROP
        IFS=',' read -ra DROP_MCPS <<< "$CUSTOM_DROP"
        KEEP_MCPS=()
        ;;
    *)
        echo "Unknown mode: $MODE" >&2
        exit 1
        ;;
esac

# Step 1: Create checkpoint file
if [ -n "$CHECKPOINT_CONTENT" ]; then
    mkdir -p "$(dirname "$CHECKPOINT_FILE")"
    cat > "$CHECKPOINT_FILE" << EOF
# Soft Restart Checkpoint

**Created**: $TIMESTAMP
**Mode**: $MODE

## Context
$CHECKPOINT_CONTENT

## MCP Configuration
- **Kept**: ${KEEP_MCPS[*]:-"(Tier 1 only)"}
- **Dropped**: ${DROP_MCPS[*]}

## Instructions
Resume work by saying "continue" or describing what to do next.
EOF
    log "Checkpoint file created: $CHECKPOINT_FILE"
else
    log "No checkpoint content provided, skipping checkpoint file"
fi

# Step 2: Remove MCPs from config
REMOVED_COUNT=0
for mcp in "${DROP_MCPS[@]}"; do
    if claude mcp list 2>/dev/null | grep -q "^$mcp:"; then
        claude mcp remove "$mcp" -s local 2>/dev/null
        log "Removed MCP: $mcp"
        ((REMOVED_COUNT++))
    else
        log "MCP not found (skipped): $mcp"
    fi
done

# Step 3: Output summary
echo "============================================"
echo "MCP UNLOAD WORKFLOW COMPLETE"
echo "============================================"
echo ""
echo "Mode: $MODE"
echo "MCPs removed: $REMOVED_COUNT"
echo "  Dropped: ${DROP_MCPS[*]}"
echo "  Kept: ${KEEP_MCPS[*]:-"(Tier 1 only)"}"
echo ""
if [ -f "$CHECKPOINT_FILE" ]; then
    echo "Checkpoint: Created"
else
    echo "Checkpoint: Not created (no content provided)"
fi
echo ""
echo "============================================"
echo "NEXT STEPS"
echo "============================================"
echo ""
echo "Option A (Soft restart - /clear):"
echo "  1. Type: /clear"
echo "  2. MCPs remain loaded (same process)"
echo "  3. Checkpoint will be displayed"
echo ""
echo "Option B (Hard restart - exit + claude):"
echo "  1. Type: exit (or Ctrl+C)"
echo "  2. Type: claude"
echo "  3. MCPs will be reduced per config"
echo "  4. Checkpoint will be displayed"
echo ""
echo "For MCP reduction, use Option B."
echo "============================================"

log "Workflow complete - removed $REMOVED_COUNT MCPs"
exit 0

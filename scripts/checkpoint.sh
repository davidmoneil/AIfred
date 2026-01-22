#!/bin/bash
# Script: checkpoint.sh
# Purpose: Save session state for continuation after restart
# Usage: ./checkpoint.sh [reason]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -euo pipefail

# Configuration
AIPROJECTS_DIR="${HOME}/AIProjects"
SESSION_STATE="${AIPROJECTS_DIR}/.claude/context/session-state.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [options] [reason]

Save session state for continuation after restart.

Arguments:
    reason          Optional reason for checkpoint (e.g., "MCP restart needed")

Options:
    -m, --mcp NAME  Specify MCP that requires restart
    -s, --summary   Summary of current work (prompted if not provided)
    -h, --help      Show this help

Examples:
    $(basename "$0") "Need to enable n8n MCP"
    $(basename "$0") --mcp n8n-mcp "Workflow automation needed"
    $(basename "$0")  # Interactive mode

On-Demand MCPs:
    n8n-mcp      (~28k tokens) - Workflow automation
    github       (~15k tokens) - Remote operations
    ssh          (~5k tokens)  - Remote system access
    prometheus   (~8k tokens)  - Metrics queries
    grafana      (~10k tokens) - Dashboard access

Exit Codes:
    0  Success
    1  Invalid arguments
    2  Failed to update session state
EOF
}

# Logging
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Parse arguments
REASON=""
MCP_NAME=""
SUMMARY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -m|--mcp) MCP_NAME="$2"; shift 2 ;;
        -s|--summary) SUMMARY="$2"; shift 2 ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$REASON" ]]; then
                REASON="$1"
            fi
            shift
            ;;
    esac
done

# Get current timestamp
TIMESTAMP=$(date -Iseconds)
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

log_info "Creating checkpoint at $TIME"

# Check if session-state.md exists
if [[ ! -f "$SESSION_STATE" ]]; then
    log_warning "Session state file not found, creating..."
    mkdir -p "$(dirname "$SESSION_STATE")"
    cat > "$SESSION_STATE" << 'EOF'
# Session State

**Status**: idle
**Last Updated**:

## Current Work

[No active work]

## Next Steps

[None]
EOF
fi

# Read current session state for context
CURRENT_STATUS=$(grep -E "^\*\*Status\*\*:" "$SESSION_STATE" | head -1 | sed 's/.*: //' || echo "unknown")
log_info "Current status: $CURRENT_STATUS"

# Build checkpoint content
CHECKPOINT_REASON="${REASON:-Manual checkpoint}"
if [[ -n "$MCP_NAME" ]]; then
    CHECKPOINT_REASON="MCP required: $MCP_NAME - $REASON"
fi

# Update session-state.md with checkpoint info
# We'll update the Status and Last Updated lines, and add checkpoint section

# Create temp file with updates
TEMP_FILE=$(mktemp)

# Update status line
sed "s/^\*\*Status\*\*:.*/\*\*Status\*\*: checkpoint/" "$SESSION_STATE" > "$TEMP_FILE"

# Update last updated line
sed -i "s/^\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $DATE $TIME/" "$TEMP_FILE"

# Check if checkpoint section exists, if not add it
if ! grep -q "## Checkpoint" "$TEMP_FILE"; then
    # Add checkpoint section before "## Current Work" or at end
    if grep -q "## Current Work" "$TEMP_FILE"; then
        sed -i "/## Current Work/i\\
## Checkpoint\\
\\
**Timestamp**: $TIMESTAMP\\
**Reason**: $CHECKPOINT_REASON\\
$(if [[ -n "$MCP_NAME" ]]; then echo "**MCP Required**: $MCP_NAME"; fi)\\
\\
### To Resume\\
\\
1. Enable required MCP: \`claude mcp add $MCP_NAME\`\\
2. Restart Claude Code\\
3. Continue from session-state.md context\\
\\
---\\
" "$TEMP_FILE"
    else
        cat >> "$TEMP_FILE" << EOF

## Checkpoint

**Timestamp**: $TIMESTAMP
**Reason**: $CHECKPOINT_REASON
$(if [[ -n "$MCP_NAME" ]]; then echo "**MCP Required**: $MCP_NAME"; fi)

### To Resume

1. Enable required MCP: \`claude mcp add $MCP_NAME\`
2. Restart Claude Code
3. Continue from session-state.md context
EOF
    fi
else
    # Update existing checkpoint section
    sed -i "s/^\*\*Timestamp\*\*:.*/\*\*Timestamp\*\*: $TIMESTAMP/" "$TEMP_FILE"
    sed -i "s/^\*\*Reason\*\*:.*/\*\*Reason\*\*: $CHECKPOINT_REASON/" "$TEMP_FILE"
    if [[ -n "$MCP_NAME" ]]; then
        if grep -q "^\*\*MCP Required\*\*:" "$TEMP_FILE"; then
            sed -i "s/^\*\*MCP Required\*\*:.*/\*\*MCP Required\*\*: $MCP_NAME/" "$TEMP_FILE"
        fi
    fi
fi

# Move temp file to session state
mv "$TEMP_FILE" "$SESSION_STATE"

log_success "Session state updated"

# Output summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}              CHECKPOINT SAVED${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}Reason:${NC}    $CHECKPOINT_REASON"
echo -e "  ${BLUE}Timestamp:${NC} $TIMESTAMP"
if [[ -n "$MCP_NAME" ]]; then
echo -e "  ${BLUE}MCP:${NC}       $MCP_NAME"
fi
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

# If MCP specified, show enable instructions
if [[ -n "$MCP_NAME" ]]; then
    echo ""
    echo -e "${YELLOW}To continue after restart:${NC}"
    echo ""
    echo "  1. Enable MCP:"
    echo "     claude mcp add $MCP_NAME"
    echo ""
    echo "  2. Restart Claude Code"
    echo ""
    echo "  3. Session will resume from checkpoint"
    echo ""
fi

# Show session state location
echo -e "${BLUE}Session state:${NC} $SESSION_STATE"
echo ""

exit 0

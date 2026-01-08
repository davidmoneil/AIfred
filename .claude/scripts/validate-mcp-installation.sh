#!/bin/bash
# MCP Installation Validation Script
# Part of PR-8.4: MCP Validation Harness
# Usage: ./validate-mcp-installation.sh [mcp-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/.claude/logs/mcp-validation"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory if needed
mkdir -p "$LOG_DIR"

usage() {
    echo "Usage: $0 [mcp-name|--list|--all]"
    echo ""
    echo "Options:"
    echo "  mcp-name    Validate specific MCP"
    echo "  --list      List all registered MCPs"
    echo "  --all       Validate all enabled MCPs"
    echo ""
    echo "Examples:"
    echo "  $0 git"
    echo "  $0 --list"
    echo "  $0 --all"
}

log_result() {
    local status=$1
    local message=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}[✓]${NC} $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}[✗]${NC} $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}[!]${NC} $message"
    else
        echo -e "${BLUE}[i]${NC} $message"
    fi
}

list_mcps() {
    echo -e "${BLUE}=== Registered MCPs ===${NC}"
    echo ""

    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        log_result "FAIL" "Claude CLI not found in PATH"
        exit 1
    fi

    # List MCPs using claude command
    claude mcp list 2>/dev/null || {
        log_result "FAIL" "Failed to list MCPs"
        exit 1
    }
}

validate_mcp() {
    local mcp_name=$1
    local log_file="$LOG_DIR/${mcp_name}-$(date +%Y%m%d).md"

    echo -e "${BLUE}=== Validating MCP: $mcp_name ===${NC}"
    echo ""

    # Initialize log file
    cat > "$log_file" << EOF
# $mcp_name Validation Results

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Script**: validate-mcp-installation.sh

## Phase 1: Installation Verification

EOF

    # Check 1: MCP appears in registered list
    echo "Checking registration..."
    if claude mcp list 2>/dev/null | grep -qi "$mcp_name"; then
        log_result "PASS" "MCP '$mcp_name' is registered"
        echo "- [x] MCP registered in Claude" >> "$log_file"
    else
        log_result "FAIL" "MCP '$mcp_name' not found in registered MCPs"
        echo "- [ ] MCP registered in Claude - **NOT FOUND**" >> "$log_file"
        return 1
    fi

    # Check 2: Configuration location
    echo "Checking configuration..."
    local config_found=false
    local config_location=""

    # Check project-level .mcp.json
    if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
        if grep -qi "\"$mcp_name\"" "$PROJECT_ROOT/.mcp.json" 2>/dev/null; then
            config_found=true
            config_location="Project (.mcp.json)"
        fi
    fi

    # Check global ~/.claude.json
    if [ -f "$HOME/.claude.json" ]; then
        if grep -qi "\"$mcp_name\"" "$HOME/.claude.json" 2>/dev/null; then
            config_found=true
            config_location="${config_location:+$config_location, }Global (~/.claude.json)"
        fi
    fi

    if [ "$config_found" = true ]; then
        log_result "PASS" "Configuration found: $config_location"
        echo "- [x] Configuration location: $config_location" >> "$log_file"
    else
        log_result "WARN" "Configuration not found in expected locations"
        echo "- [ ] Configuration location: Not found in .mcp.json or ~/.claude.json" >> "$log_file"
    fi

    # Check 3: Disabled status
    echo "Checking enabled status..."
    if [ -f "$HOME/.claude.json" ]; then
        # Check if MCP is in disabledMcpServers
        if grep -A 100 "disabledMcpServers" "$HOME/.claude.json" 2>/dev/null | grep -qi "\"$mcp_name\""; then
            log_result "WARN" "MCP '$mcp_name' is currently DISABLED"
            echo "- [ ] MCP enabled - **DISABLED in disabledMcpServers**" >> "$log_file"
        else
            log_result "PASS" "MCP '$mcp_name' is enabled"
            echo "- [x] MCP is enabled (not in disabledMcpServers)" >> "$log_file"
        fi
    fi

    echo ""
    echo "## Summary" >> "$log_file"
    echo "" >> "$log_file"
    echo "Installation verification complete. See Claude session for Phase 2-5 validation." >> "$log_file"

    log_result "INFO" "Log written to: $log_file"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Run /validate-mcp $mcp_name in Claude for full validation"
    echo "  2. Or invoke the MCP tools directly to verify functionality"
}

# Main
case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    --list)
        list_mcps
        exit 0
        ;;
    --all)
        echo -e "${BLUE}Validating all MCPs...${NC}"
        echo ""
        # Get list and validate each
        for mcp in $(claude mcp list 2>/dev/null | grep -E "^\s*\w+" | awk '{print $1}'); do
            validate_mcp "$mcp"
            echo ""
        done
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        validate_mcp "$1"
        ;;
esac

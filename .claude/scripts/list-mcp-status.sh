#!/bin/bash
#
# list-mcp-status.sh - Show MCP registration and disabled status
#
# Usage: ./list-mcp-status.sh
#
# Shows which MCPs are registered (in mcpServers) vs disabled (in disabledMcpServers)
#
# Created: 2026-01-07
# Key Discovery: disabledMcpServers array in ~/.claude.json
#

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "════════════════════════════════════════════════════════════"
echo "                    MCP Status Report"
echo "════════════════════════════════════════════════════════════"
echo ""

# Get registered MCPs (local project scope)
echo -e "${CYAN}Registered MCPs (mcpServers):${NC}"
REGISTERED=$(jq -r --arg path "$PROJECT_PATH" '.projects[$path].mcpServers // {} | keys[]' "$CONFIG_FILE" 2>/dev/null)
if [ -z "$REGISTERED" ]; then
  echo "  (none registered at project level)"
else
  for mcp in $REGISTERED; do
    echo "  - $mcp"
  done
fi

echo ""

# Get disabled MCPs
echo -e "${CYAN}Disabled MCPs (disabledMcpServers):${NC}"
DISABLED=$(jq -r --arg path "$PROJECT_PATH" '.projects[$path].disabledMcpServers // [] | .[]' "$CONFIG_FILE" 2>/dev/null)
if [ -z "$DISABLED" ]; then
  echo "  (none disabled)"
else
  for mcp in $DISABLED; do
    echo -e "  - $mcp ${RED}(will not load)${NC}"
  done
fi

echo ""

# Summary
echo -e "${CYAN}Summary:${NC}"
REG_COUNT=$(echo "$REGISTERED" | grep -c . 2>/dev/null || echo "0")
DIS_COUNT=$(echo "$DISABLED" | grep -c . 2>/dev/null || echo "0")
echo "  Registered: $REG_COUNT"
echo "  Disabled:   $DIS_COUNT"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${YELLOW}Note:${NC} Run 'claude mcp list' in session to see runtime state"
echo "════════════════════════════════════════════════════════════"
echo ""

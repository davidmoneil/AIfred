#!/bin/bash
#
# adjust-mcp-config.sh - Adjust MCP configuration for context optimization
#
# Usage: ./adjust-mcp-config.sh [tier1-only|keep-github|keep-context7|keep-all]
#
# Created: 2026-01-07
# PR Reference: PR-8.4 / PR-9.2
#

set -e

# MCP tier definitions
TIER1_MCPS="memory filesystem fetch git"
TIER2_MCPS="time github context7 sequential-thinking"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "════════════════════════════════════════════════════════════"
echo "           MCP Configuration Adjustment Script"
echo "════════════════════════════════════════════════════════════"
echo ""

# Parse argument
MODE="${1:-tier1-only}"

case "$MODE" in
  tier1-only)
    echo -e "${YELLOW}Mode: Tier 1 Only${NC}"
    echo "Keeping: $TIER1_MCPS"
    echo "Removing: $TIER2_MCPS"
    REMOVE_LIST="$TIER2_MCPS"
    ;;
  keep-github)
    echo -e "${YELLOW}Mode: Keep GitHub${NC}"
    echo "Keeping: $TIER1_MCPS github"
    echo "Removing: time context7 sequential-thinking"
    REMOVE_LIST="time context7 sequential-thinking"
    ;;
  keep-context7)
    echo -e "${YELLOW}Mode: Keep Context7${NC}"
    echo "Keeping: $TIER1_MCPS context7"
    echo "Removing: time github sequential-thinking"
    REMOVE_LIST="time github sequential-thinking"
    ;;
  keep-all)
    echo -e "${GREEN}Mode: Keep All${NC}"
    echo "No MCPs will be removed."
    REMOVE_LIST=""
    ;;
  *)
    echo -e "${RED}Unknown mode: $MODE${NC}"
    echo "Valid modes: tier1-only, keep-github, keep-context7, keep-all"
    exit 1
    ;;
esac

echo ""

# Check if any MCPs need to be removed
if [ -z "$REMOVE_LIST" ]; then
  echo -e "${GREEN}No MCPs to remove. Configuration unchanged.${NC}"
  exit 0
fi

# Remove each MCP
echo "Removing Tier 2 MCPs..."
echo ""

for mcp in $REMOVE_LIST; do
  # Check if MCP exists in config
  if claude mcp list 2>/dev/null | grep -q "^$mcp:"; then
    echo -n "  Removing $mcp... "
    if claude mcp remove "$mcp" -s local 2>/dev/null; then
      echo -e "${GREEN}OK${NC}"
    else
      echo -e "${YELLOW}Not found or already removed${NC}"
    fi
  else
    echo -e "  $mcp: ${YELLOW}Not in config${NC}"
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}MCP config adjustment complete!${NC}"
echo ""
echo "Changes take effect on next Claude Code session."
echo "Run 'claude' to start with optimized MCP load."
echo "════════════════════════════════════════════════════════════"
echo ""

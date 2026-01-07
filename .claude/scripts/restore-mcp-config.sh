#!/bin/bash
#
# restore-mcp-config.sh - Re-add removed Tier 2 MCPs
#
# Usage: ./restore-mcp-config.sh [mcp-name|all]
#
# Created: 2026-01-07
# PR Reference: PR-8.4 / PR-9.2
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "════════════════════════════════════════════════════════════"
echo "           MCP Configuration Restore Script"
echo "════════════════════════════════════════════════════════════"
echo ""

# MCP add commands (with full arguments)
add_time() {
  claude mcp add time -s local -- uvx mcp-server-time
}

add_github() {
  # Note: Requires GITHUB_PERSONAL_ACCESS_TOKEN env var
  claude mcp add github -s local -- npx -y @modelcontextprotocol/server-github
}

add_context7() {
  # Note: API key stored in ~/.zshrc or needs to be provided
  local API_KEY="${CONTEXT7_API_KEY:-ctx7sk-33ff4efb-ef82-41e2-b4fb-b2628f1298f7}"
  claude mcp add context7 -s local -- npx -y @upstash/context7-mcp --api-key "$API_KEY"
}

add_sequential_thinking() {
  claude mcp add sequential-thinking -s local -- npx -y @modelcontextprotocol/server-sequential-thinking
}

# Parse argument
MCP="${1:-help}"

case "$MCP" in
  time)
    echo "Adding Time MCP..."
    add_time
    echo -e "${GREEN}Time MCP added.${NC}"
    ;;
  github)
    echo "Adding GitHub MCP..."
    add_github
    echo -e "${GREEN}GitHub MCP added.${NC}"
    ;;
  context7)
    echo "Adding Context7 MCP..."
    add_context7
    echo -e "${GREEN}Context7 MCP added.${NC}"
    ;;
  sequential-thinking)
    echo "Adding Sequential Thinking MCP..."
    add_sequential_thinking
    echo -e "${GREEN}Sequential Thinking MCP added.${NC}"
    ;;
  all)
    echo "Adding all Tier 2 MCPs..."
    echo ""
    echo -n "  time... "
    add_time && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Failed${NC}"
    echo -n "  github... "
    add_github && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Failed${NC}"
    echo -n "  context7... "
    add_context7 && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Failed${NC}"
    echo -n "  sequential-thinking... "
    add_sequential_thinking && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Failed${NC}"
    ;;
  help|*)
    echo "Usage: $0 [mcp-name|all]"
    echo ""
    echo "Available MCPs:"
    echo "  time                - Time/timezone operations (~3K tokens)"
    echo "  github              - GitHub PR/issue operations (~15K tokens)"
    echo "  context7            - Documentation lookup (~8K tokens)"
    echo "  sequential-thinking - Complex planning (~5K tokens)"
    echo "  all                 - Add all Tier 2 MCPs"
    echo ""
    echo "Example:"
    echo "  $0 github           # Add GitHub MCP only"
    echo "  $0 all              # Add all Tier 2 MCPs"
    exit 0
    ;;
esac

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Changes take effect on next Claude Code session."
echo "Run 'claude' to start with updated MCP configuration."
echo "════════════════════════════════════════════════════════════"
echo ""

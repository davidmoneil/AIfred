#!/bin/bash
#
# disable-mcps.sh - Disable MCPs by adding to disabledMcpServers array
#
# Usage: ./disable-mcps.sh <server-name> [server-name...]
#
# This script modifies ~/.claude.json to add MCPs to the disabledMcpServers
# array for the current project. Changes take effect after /clear or restart.
#
# Created: 2026-01-07
# Key Discovery: disabledMcpServers array in ~/.claude.json
#

set -e

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
  echo -e "${YELLOW}Usage: disable-mcps.sh <server-name> [server-name...]${NC}"
  echo ""
  echo "Examples:"
  echo "  disable-mcps.sh git"
  echo "  disable-mcps.sh github context7 sequential-thinking"
  echo ""
  echo "Currently disabled MCPs:"
  jq -r --arg path "$PROJECT_PATH" '.projects[$path].disabledMcpServers // [] | .[]' "$CONFIG_FILE" 2>/dev/null || echo "  (none)"
  exit 1
fi

# Verify jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq is required but not installed.${NC}"
  echo "Install with: brew install jq"
  exit 1
fi

# Verify config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
  exit 1
fi

echo ""
echo "Disabling MCPs..."
echo ""

for SERVER in "$@"; do
  # Check if already disabled
  if jq -e --arg path "$PROJECT_PATH" --arg server "$SERVER" \
    '.projects[$path].disabledMcpServers // [] | index($server) != null' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo -e "  $SERVER: ${YELLOW}Already disabled${NC}"
  else
    # Add to disabledMcpServers array
    jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
      .projects[$path].disabledMcpServers = ((.projects[$path].disabledMcpServers // []) + [$server] | unique)
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo -e "  $SERVER: ${GREEN}Disabled${NC}"
  fi
done

echo ""
echo -e "${GREEN}Done.${NC} Changes take effect after /clear"
echo ""

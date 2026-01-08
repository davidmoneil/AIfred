#!/bin/bash
#
# enable-mcps.sh - Enable MCPs by removing from disabledMcpServers array
#
# Usage: ./enable-mcps.sh <server-name> [server-name...]
#        ./enable-mcps.sh --all
#
# This script modifies ~/.claude.json to remove MCPs from the disabledMcpServers
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
  echo -e "${YELLOW}Usage: enable-mcps.sh <server-name> [server-name...]${NC}"
  echo "       enable-mcps.sh --all"
  echo ""
  echo "Examples:"
  echo "  enable-mcps.sh git"
  echo "  enable-mcps.sh github context7"
  echo "  enable-mcps.sh --all  # Enable all disabled MCPs"
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

# Handle --all flag
if [ "$1" = "--all" ]; then
  echo "Enabling ALL disabled MCPs..."
  echo ""

  # Get list of disabled MCPs
  DISABLED=$(jq -r --arg path "$PROJECT_PATH" '.projects[$path].disabledMcpServers // [] | .[]' "$CONFIG_FILE" 2>/dev/null)

  if [ -z "$DISABLED" ]; then
    echo -e "  ${YELLOW}No MCPs are currently disabled${NC}"
  else
    for SERVER in $DISABLED; do
      echo -e "  $SERVER: ${GREEN}Enabled${NC}"
    done

    # Clear the array
    jq --arg path "$PROJECT_PATH" '
      .projects[$path].disabledMcpServers = []
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  fi
else
  echo "Enabling MCPs..."
  echo ""

  for SERVER in "$@"; do
    # Check if currently disabled
    if jq -e --arg path "$PROJECT_PATH" --arg server "$SERVER" \
      '.projects[$path].disabledMcpServers // [] | index($server) != null' "$CONFIG_FILE" > /dev/null 2>&1; then
      # Remove from disabledMcpServers array
      jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
        .projects[$path].disabledMcpServers = ((.projects[$path].disabledMcpServers // []) - [$server])
      ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      echo -e "  $SERVER: ${GREEN}Enabled${NC}"
    else
      echo -e "  $SERVER: ${YELLOW}Was not disabled${NC}"
    fi
  done
fi

echo ""
echo -e "${GREEN}Done.${NC} Changes take effect after /clear"
echo ""

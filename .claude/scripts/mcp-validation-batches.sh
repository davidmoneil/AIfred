#!/bin/bash
#
# mcp-validation-batches.sh - Configure MCP batches for validation testing
#
# Usage: ./mcp-validation-batches.sh <batch-number>
#        ./mcp-validation-batches.sh list
#        ./mcp-validation-batches.sh reset
#
# Batches are designed to:
# - Keep total tool tokens under ~30K (safe margin from ~45K limit)
# - Group related MCPs together
# - Always include Tier 1 core MCPs
#
# Created: 2026-01-08
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# All registered MCPs
ALL_MCPS=(
  "memory"
  "filesystem"
  "fetch"
  "git"
  "github"
  "context7"
  "sequential-thinking"
  "arxiv"
  "brave-search"
  "datetime"
  "lotus-wisdom"
  "chroma"
  "desktop-commander"
  "wikipedia"
  "playwright"
  "perplexity"
  "gptresearcher"
)

# Tier 1 Core (always included) - ~7.6K tokens
TIER1_CORE=("memory" "filesystem" "fetch" "git")

# Batch definitions (each ~20-25K additional tokens)
# Batch 1: Development MCPs
BATCH1_EXTRA=("github" "context7" "sequential-thinking" "datetime")
BATCH1_DESC="Development (github, context7, sequential-thinking, datetime)"

# Batch 2: Research MCPs
BATCH2_EXTRA=("brave-search" "arxiv" "perplexity" "wikipedia")
BATCH2_DESC="Research (brave-search, arxiv, perplexity, wikipedia)"

# Batch 3: Utility MCPs
BATCH3_EXTRA=("desktop-commander" "chroma" "gptresearcher")
BATCH3_DESC="Utilities (desktop-commander, chroma, gptresearcher)"

# Batch 4: Specialized MCPs
BATCH4_EXTRA=("playwright" "lotus-wisdom")
BATCH4_DESC="Specialized (playwright, lotus-wisdom)"

show_usage() {
  echo ""
  echo -e "${BLUE}MCP Validation Batch Configuration${NC}"
  echo ""
  echo "Usage:"
  echo "  $0 <batch-number>   Configure MCPs for batch N (1-4)"
  echo "  $0 list             Show all batch definitions"
  echo "  $0 reset            Enable all MCPs (restore full config)"
  echo ""
  echo "After running, use /clear to apply changes."
  echo ""
}

list_batches() {
  echo ""
  echo -e "${BLUE}MCP Validation Batches${NC}"
  echo ""
  echo -e "${GREEN}Tier 1 Core (always included):${NC}"
  echo "  ${TIER1_CORE[*]}"
  echo "  Estimated tokens: ~7.6K"
  echo ""
  echo -e "${YELLOW}Batch 1: $BATCH1_DESC${NC}"
  echo "  ${BATCH1_EXTRA[*]}"
  echo "  Total MCPs: $((${#TIER1_CORE[@]} + ${#BATCH1_EXTRA[@]}))"
  echo ""
  echo -e "${YELLOW}Batch 2: $BATCH2_DESC${NC}"
  echo "  ${BATCH2_EXTRA[*]}"
  echo "  Total MCPs: $((${#TIER1_CORE[@]} + ${#BATCH2_EXTRA[@]}))"
  echo ""
  echo -e "${YELLOW}Batch 3: $BATCH3_DESC${NC}"
  echo "  ${BATCH3_EXTRA[*]}"
  echo "  Total MCPs: $((${#TIER1_CORE[@]} + ${#BATCH3_EXTRA[@]}))"
  echo ""
  echo -e "${YELLOW}Batch 4: $BATCH4_DESC${NC}"
  echo "  ${BATCH4_EXTRA[*]}"
  echo "  Total MCPs: $((${#TIER1_CORE[@]} + ${#BATCH4_EXTRA[@]}))"
  echo ""
}

configure_batch() {
  local batch_num=$1
  local batch_desc
  local batch_extra

  case $batch_num in
    1)
      batch_extra="github context7 sequential-thinking datetime"
      batch_desc="$BATCH1_DESC"
      ;;
    2)
      batch_extra="brave-search arxiv perplexity wikipedia"
      batch_desc="$BATCH2_DESC"
      ;;
    3)
      batch_extra="desktop-commander chroma gptresearcher"
      batch_desc="$BATCH3_DESC"
      ;;
    4)
      batch_extra="playwright lotus-wisdom"
      batch_desc="$BATCH4_DESC"
      ;;
    *)
      echo -e "${RED}Error: Invalid batch number. Use 1-4.${NC}"
      exit 1
      ;;
  esac

  # Build list of MCPs to enable for this batch (core + batch extras)
  local enabled_mcps="${TIER1_CORE[*]} $batch_extra"

  # Build list of MCPs to disable (all others)
  local disabled_mcps=""
  for mcp in "${ALL_MCPS[@]}"; do
    if [[ ! " $enabled_mcps " =~ " $mcp " ]]; then
      disabled_mcps="$disabled_mcps $mcp"
    fi
  done

  echo ""
  echo -e "${BLUE}Configuring Batch $batch_num: $batch_desc${NC}"
  echo ""
  echo -e "${GREEN}Enabling:${NC}"
  for mcp in $enabled_mcps; do
    echo "  ✓ $mcp"
  done
  echo ""
  echo -e "${YELLOW}Disabling:${NC}"
  for mcp in $disabled_mcps; do
    echo "  ✗ $mcp"
  done
  echo ""

  # Clear existing disabled list and add new ones
  jq --arg path "$PROJECT_PATH" '
    .projects[$path].disabledMcpServers = []
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

  # Disable the MCPs not in this batch
  for mcp in $disabled_mcps; do
    jq --arg path "$PROJECT_PATH" --arg server "$mcp" '
      .projects[$path].disabledMcpServers = ((.projects[$path].disabledMcpServers // []) + [$server] | unique)
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  done

  echo -e "${GREEN}Done.${NC} Run /clear to apply changes."
  echo ""
  echo "After /clear, test these MCPs:"
  for mcp in $enabled_mcps; do
    echo "  - $mcp"
  done
  echo ""
}

reset_all() {
  echo ""
  echo -e "${BLUE}Resetting to full MCP configuration${NC}"
  echo ""

  # Clear the disabled list
  jq --arg path "$PROJECT_PATH" '
    .projects[$path].disabledMcpServers = []
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

  echo -e "${GREEN}All MCPs enabled.${NC} Run /clear to apply changes."
  echo ""
}

# Main
case "${1:-}" in
  ""|"-h"|"--help")
    show_usage
    ;;
  "list")
    list_batches
    ;;
  "reset")
    reset_all
    ;;
  [1-4])
    configure_batch "$1"
    ;;
  *)
    echo -e "${RED}Error: Unknown option '$1'${NC}"
    show_usage
    exit 1
    ;;
esac

#!/bin/bash
#
# suggest-mcps.sh - Analyze session-state.md and suggest MCPs for session
#
# Usage:
#   ./suggest-mcps.sh              # Suggest MCPs based on "Next Step"
#   ./suggest-mcps.sh --capture    # Capture currently enabled MCPs
#   ./suggest-mcps.sh --json       # Output as JSON (for hooks)
#
# Analyzes session-state.md "Next Step" field for keywords and suggests
# appropriate Tier 2 MCPs to enable for the upcoming work.
#
# Created: 2026-01-09
# Part of: MCP Initialization Protocol (PR-8.5)
#

set -e

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
SESSION_STATE="$PROJECT_PATH/.claude/context/session-state.md"
CONFIG_FILE="$HOME/.claude.json"

# Colors (disabled in JSON mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# MCP keyword mappings (keyword -> MCP name)
# Format: "keyword:mcp1,mcp2"
declare -a MCP_KEYWORDS=(
    "PR:github"
    "pull request:github"
    "issue:github"
    "github:github"
    "documentation:context7,wikipedia"
    "library:context7"
    "docs:context7,wikipedia"
    "research:brave-search,perplexity,gptresearcher"
    "search:brave-search,perplexity"
    "paper:arxiv"
    "academic:arxiv"
    "arxiv:arxiv"
    "architecture:sequential-thinking"
    "design:sequential-thinking"
    "complex:sequential-thinking"
    "browser:playwright"
    "test:playwright"
    "QA:playwright"
    "automation:playwright"
    "vector:chroma"
    "semantic:chroma"
    "embedding:chroma"
    "time:datetime"
    "timezone:datetime"
    "schedule:datetime"
    "file:desktop-commander"
    "process:desktop-commander"
    "system:desktop-commander"
    "wikipedia:wikipedia"
    "reference:wikipedia"
    "deep research:gptresearcher"
    "comprehensive:gptresearcher"
    "perplexity:perplexity"
    "citations:perplexity"
)

# Tier 1 MCPs (always on, don't suggest)
TIER1_MCPS="memory filesystem fetch git"

# Tier 3 MCPs (warn, not auto-suggest)
TIER3_MCPS="playwright lotus-wisdom"

# Parse arguments
JSON_MODE=false
CAPTURE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            # Disable colors in JSON mode
            RED=''
            GREEN=''
            YELLOW=''
            CYAN=''
            NC=''
            shift
            ;;
        --capture)
            CAPTURE_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Function: Get currently enabled MCPs
get_enabled_mcps() {
    # Get MCPs that are registered but NOT in disabledMcpServers
    local registered=$(jq -r --arg path "$PROJECT_PATH" '.projects[$path].mcpServers // {} | keys[]' "$CONFIG_FILE" 2>/dev/null)
    local disabled=$(jq -r --arg path "$PROJECT_PATH" '.projects[$path].disabledMcpServers // [] | .[]' "$CONFIG_FILE" 2>/dev/null)

    # Filter out disabled ones
    for mcp in $registered; do
        if ! echo "$disabled" | grep -q "^${mcp}$"; then
            echo "$mcp"
        fi
    done
}

# Function: Get "Next Step" from session-state.md
get_next_step() {
    if [[ -f "$SESSION_STATE" ]]; then
        # Extract text after "**Next Step**:" until next section or empty line
        sed -n '/\*\*Next Step\*\*:/,/^\*\*\|^$/p' "$SESSION_STATE" | head -5 | tr '\n' ' '
    else
        echo ""
    fi
}

# Function: Analyze text and suggest MCPs
suggest_mcps_for_text() {
    local text="$1"
    local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    local suggested=""

    for mapping in "${MCP_KEYWORDS[@]}"; do
        local keyword="${mapping%%:*}"
        local mcps="${mapping#*:}"

        if echo "$text_lower" | grep -qi "$keyword"; then
            # Add MCPs (comma-separated)
            for mcp in $(echo "$mcps" | tr ',' ' '); do
                # Skip if already in suggested or is Tier 1
                if ! echo "$suggested" | grep -q "$mcp" && ! echo "$TIER1_MCPS" | grep -q "$mcp"; then
                    suggested="$suggested $mcp"
                fi
            done
        fi
    done

    echo "$suggested" | xargs  # Trim whitespace
}

# Function: Check if MCP is Tier 3 (warn)
is_tier3() {
    echo "$TIER3_MCPS" | grep -q "$1"
}

# ============== CAPTURE MODE ==============
if $CAPTURE_MODE; then
    enabled=$(get_enabled_mcps)

    if $JSON_MODE; then
        # Output as JSON array
        echo "$enabled" | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo ""
        echo -e "${CYAN}Currently Enabled MCPs:${NC}"
        for mcp in $enabled; do
            if echo "$TIER1_MCPS" | grep -q "$mcp"; then
                echo -e "  - $mcp ${GREEN}(Tier 1 - Always On)${NC}"
            elif is_tier3 "$mcp"; then
                echo -e "  - $mcp ${YELLOW}(Tier 3 - On-Demand)${NC}"
            else
                echo -e "  - $mcp ${CYAN}(Tier 2 - Task-Scoped)${NC}"
            fi
        done
        echo ""
    fi
    exit 0
fi

# ============== SUGGESTION MODE ==============

# Get next step text
next_step=$(get_next_step)

if [[ -z "$next_step" ]]; then
    if $JSON_MODE; then
        echo '{"suggested": [], "warnings": [], "message": "No Next Step found in session-state.md"}'
    else
        echo -e "${YELLOW}No 'Next Step' found in session-state.md${NC}"
    fi
    exit 0
fi

# Analyze and get suggestions
suggested=$(suggest_mcps_for_text "$next_step")
currently_enabled=$(get_enabled_mcps)

# Build lists
to_enable=""
to_disable=""
warnings=""

# Check what needs enabling
for mcp in $suggested; do
    if ! echo "$currently_enabled" | grep -q "^${mcp}$"; then
        to_enable="$to_enable $mcp"
        if is_tier3 "$mcp"; then
            warnings="$warnings $mcp"
        fi
    fi
done

# Check Tier 2 MCPs that could be disabled (enabled but not suggested and not Tier 1)
for mcp in $currently_enabled; do
    if ! echo "$TIER1_MCPS" | grep -q "$mcp"; then
        if ! echo "$suggested" | grep -q "$mcp"; then
            # Enabled but not needed for next step
            to_disable="$to_disable $mcp"
        fi
    fi
done

# Trim whitespace
to_enable=$(echo "$to_enable" | xargs)
to_disable=$(echo "$to_disable" | xargs)
warnings=$(echo "$warnings" | xargs)

# ============== OUTPUT ==============

if $JSON_MODE; then
    # JSON output for hooks
    jq -n \
        --arg next "$next_step" \
        --arg enable "$to_enable" \
        --arg disable "$to_disable" \
        --arg warn "$warnings" \
        '{
            "next_step": $next,
            "to_enable": ($enable | split(" ") | map(select(length > 0))),
            "to_disable": ($disable | split(" ") | map(select(length > 0))),
            "tier3_warnings": ($warn | split(" ") | map(select(length > 0)))
        }'
else
    # Human-readable output
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "                  MCP Suggestions"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${CYAN}Next Step:${NC}"
    echo "  $next_step" | fold -s -w 60 | sed 's/^/  /'
    echo ""

    if [[ -n "$to_enable" ]]; then
        echo -e "${GREEN}Suggest Enabling:${NC}"
        for mcp in $to_enable; do
            if is_tier3 "$mcp"; then
                echo -e "  - $mcp ${YELLOW}(Tier 3 - high token cost)${NC}"
            else
                echo -e "  - $mcp"
            fi
        done
        echo ""
        echo -e "${CYAN}Command:${NC}"
        echo "  .claude/scripts/enable-mcps.sh $to_enable"
        echo ""
    fi

    if [[ -n "$to_disable" ]]; then
        echo -e "${YELLOW}Consider Disabling (not needed for next step):${NC}"
        for mcp in $to_disable; do
            echo "  - $mcp"
        done
        echo ""
        echo -e "${CYAN}Command:${NC}"
        echo "  .claude/scripts/disable-mcps.sh $to_disable"
        echo ""
    fi

    if [[ -z "$to_enable" && -z "$to_disable" ]]; then
        echo -e "${GREEN}MCP configuration looks good for next step.${NC}"
        echo ""
    fi

    if [[ -n "$warnings" ]]; then
        echo -e "${YELLOW}Warning:${NC} Tier 3 MCPs ($warnings) have high token cost."
        echo "         Consider using isolated invocation pattern instead."
        echo ""
    fi

    echo "════════════════════════════════════════════════════════════"
    echo ""
fi

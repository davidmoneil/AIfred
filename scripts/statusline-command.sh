#!/bin/bash
# AIfred Status Line for Claude Code
# Shows: Model | Cost | Project[:SubProject] | Branch | Assets | Docker | Memory | Context
#
# Output format (compact):
# Opus $0.23 | MyProject:GRC | main | 7S/12P/14A | D:4 | 8G/32G | [42% in:15K]
#
# Installation:
#   1. Copy to ~/.claude/statusline-command.sh
#   2. chmod +x ~/.claude/statusline-command.sh
#   3. Add to ~/.claude/settings.json:
#      { "statusLine": { "type": "command", "command": "~/.claude/statusline-command.sh" } }
#
# Dynamic project detection:
#   - Auto-detects when you cd into a registered Code project
#   - Manual override: echo "MyProject:SubName" > /tmp/claude-project-context
#   - Clear override: rm /tmp/claude-project-context

set -o pipefail

# Read JSON input from stdin
input=$(cat)

# ============================================================================
# CONFIGURATION — Customize these for your environment
# ============================================================================

# Your main project directory (where Claude Code launches)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/AIProjects}"

# Directory where code projects live
CODE_DIR="$HOME/Code"

# Cache settings
CACHE_FILE="/tmp/claude-statusline-cache"
CACHE_MAX_AGE=3600  # Refresh asset counts every hour

# Manual project context override
PROJECT_CONTEXT_FILE="/tmp/claude-project-context"

# Colors (ANSI)
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_DIM='\033[2m'
C_BOLD='\033[1m'

# ============================================================================
# PROJECT NAME MAPPING — Add your projects here
# ============================================================================

map_friendly_name() {
    # Map directory names to short display names
    # Add entries for your projects below
    case "$1" in
        # Example mappings (customize these):
        # my-long-project-name) echo "ShortName" ;;
        # grc-platform)         echo "GRC" ;;
        # cisoexpert-site)      echo "CISO" ;;
        *)                      echo "$1" ;;
    esac
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

format_tokens() {
    local val=$1
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        echo "0"
    elif [ "$val" -ge 1000000 ]; then
        echo "$((val / 1000000))M"
    elif [ "$val" -ge 1000 ]; then
        echo "$((val / 1000))K"
    else
        echo "$val"
    fi
}

format_cost() {
    local cost=$1
    if [ -z "$cost" ] || [ "$cost" = "null" ]; then
        echo "\$0.00"
    else
        printf "\$%.2f" "$cost"
    fi
}

format_memory() {
    local mem_info=$(free -g 2>/dev/null | awk '/^Mem:/ {printf "%dG/%dG", $3, $2}')
    echo "${mem_info:-N/A}"
}

get_docker_count() {
    local count=$(docker ps -q 2>/dev/null | wc -l)
    echo "${count:-0}"
}

get_git_branch() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        if [ ${#branch} -gt 15 ]; then
            echo "${branch:0:12}..."
        else
            echo "$branch"
        fi
    else
        echo ""
    fi
}

get_project_name() {
    # Priority 1: Manual override via marker file
    if [ -f "$PROJECT_CONTEXT_FILE" ]; then
        local override=$(cat "$PROJECT_CONTEXT_FILE" 2>/dev/null)
        if [ -n "$override" ]; then
            echo "$override"
            return
        fi
    fi

    # Priority 2: Detect from current working directory
    local current_dir=$(echo "$input" | jq -r '.cwd // empty')
    [ -z "$current_dir" ] && current_dir=$(pwd)

    local project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
    [ -z "$project_dir" ] && project_dir=$(pwd)

    local base=$(basename "$project_dir")
    local hub=$(map_friendly_name "$base")

    # Check if cwd is inside the Code directory
    if [[ "$current_dir" == "$CODE_DIR/"* ]]; then
        local rel="${current_dir#$CODE_DIR/}"
        local subproject="${rel%%/*}"
        local friendly=$(map_friendly_name "$subproject")
        echo "${hub}:${friendly}"
        return
    fi

    # Default: just the hub name
    echo "$hub"
}

# ============================================================================
# CACHED ASSET COUNTS (refresh hourly)
# ============================================================================

get_asset_counts() {
    local now=$(date +%s)
    local cache_age=999999

    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        cache_age=$((now - cache_time))
    fi

    if [ $cache_age -gt $CACHE_MAX_AGE ]; then
        local skills=$(find "$PROJECT_DIR/.claude/skills" -maxdepth 1 -type d 2>/dev/null | wc -l)
        skills=$((skills - 1))
        [ $skills -lt 0 ] && skills=0

        local patterns=$(find "$PROJECT_DIR/.claude/context/patterns" -name "*.md" 2>/dev/null | wc -l)

        local agents=$(find "$PROJECT_DIR/.claude/agents" -maxdepth 1 -name "*.md" 2>/dev/null | grep -v -E "(template|ROADMAP)" | wc -l)

        echo "${skills}S/${patterns}P/${agents}A" > "$CACHE_FILE"
    fi

    cat "$CACHE_FILE" 2>/dev/null || echo "?S/?P/?A"
}

# ============================================================================
# EXTRACT DATA FROM JSON
# ============================================================================

# Model
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# Cost
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost=$(format_cost "$cost_raw")

# Context window
usage=$(echo "$input" | jq -r '.context_window.current_usage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

if [ -n "$usage" ] && [ "$usage" != "null" ]; then
    input_tokens=$(echo "$usage" | jq -r '.input_tokens // 0')
    cache_create=$(echo "$usage" | jq -r '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$usage" | jq -r '.cache_read_input_tokens // 0')

    current_total=$((input_tokens + cache_create + cache_read))
    pct=$((current_total * 100 / window_size))

    input_fmt=$(format_tokens $input_tokens)

    if [ $pct -ge 80 ]; then
        ctx_color='\033[0;31m'  # Red
    elif [ $pct -ge 60 ]; then
        ctx_color='\033[0;33m'  # Yellow
    else
        ctx_color='\033[0;32m'  # Green
    fi

    ctx_info="${ctx_color}${pct}%${C_RESET} ${input_fmt}"
else
    ctx_info="0%"
fi

# ============================================================================
# GATHER SYSTEM INFO
# ============================================================================

project=$(get_project_name)
branch=$(get_git_branch)
assets=$(get_asset_counts)
docker_count=$(get_docker_count)
memory=$(format_memory)

# ============================================================================
# BUILD OUTPUT
# ============================================================================

output=""

# Model (bold)
output+="${C_BOLD}${model}${C_RESET}"

# Cost (green if low, yellow if moderate)
if (( $(echo "$cost_raw > 1.0" | bc -l 2>/dev/null || echo 0) )); then
    output+=" ${C_YELLOW}${cost}${C_RESET}"
elif (( $(echo "$cost_raw > 0.5" | bc -l 2>/dev/null || echo 0) )); then
    output+=" ${C_CYAN}${cost}${C_RESET}"
else
    output+=" ${C_GREEN}${cost}${C_RESET}"
fi

# Separator
output+=" ${C_DIM}|${C_RESET}"

# Project (blue)
output+=" ${C_BLUE}${project}${C_RESET}"

# Git branch (if available)
if [ -n "$branch" ]; then
    output+=" ${C_DIM}|${C_RESET} ${C_CYAN}${branch}${C_RESET}"
fi

# Separator
output+=" ${C_DIM}|${C_RESET}"

# Assets count
output+=" ${assets}"

# Docker (if containers running)
if [ "$docker_count" -gt 0 ]; then
    output+=" ${C_DIM}|${C_RESET} ${C_GREEN}D:${docker_count}${C_RESET}"
fi

# Memory
output+=" ${C_DIM}|${C_RESET} ${memory}"

# Context (in brackets)
output+=" ${C_DIM}[${C_RESET}${ctx_info}${C_DIM}]${C_RESET}"

# Output single line
printf '%b' "$output"

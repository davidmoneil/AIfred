#!/bin/bash
#
# context-staleness.sh - Find stale context files needing review
#
# Purpose: Identify context files that haven't been modified in the
#          configured period, suggesting they may need review or archiving.
#
# Usage:
#   ./context-staleness.sh              # Default 90 day threshold
#   ./context-staleness.sh --days 60    # Custom threshold
#   ./context-staleness.sh --fix        # Interactive review mode
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONTEXT_DIR="$PROJECT_ROOT/.claude/context"
LOG_FILE="$PROJECT_ROOT/.claude/jobs/logs/context-staleness.log"

# Defaults
STALENESS_DAYS=90
FIX_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$1"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            STALENESS_DAYS="$2"
            shift 2
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--days N] [--fix]"
            echo ""
            echo "Options:"
            echo "  --days N    Staleness threshold in days (default: 90)"
            echo "  --fix       Interactive review mode"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log "${BLUE}Context Staleness Analysis${NC}"
log "=========================="
log "Threshold: ${STALENESS_DAYS} days"
log "Context directory: $CONTEXT_DIR"
echo ""

# Check context directory exists
if [[ ! -d "$CONTEXT_DIR" ]]; then
    log "${RED}[FAIL]${NC} Context directory not found: $CONTEXT_DIR"
    exit 1
fi

# Find stale files (excluding templates and indexes)
STALE_FILES=()
FRESH_FILES=()
TOTAL_FILES=0

while IFS= read -r file; do
    # Skip templates and placeholder files
    filename=$(basename "$file")
    if [[ "$filename" == _template* ]] || [[ "$filename" == .gitkeep ]]; then
        continue
    fi
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # Get file modification time
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        mod_time=$(stat -f %m "$file")
        mod_date=$(date -r "$mod_time" '+%Y-%m-%d')
    else
        # Linux
        mod_date=$(date -r "$file" '+%Y-%m-%d')
        mod_time=$(date -r "$file" '+%s')
    fi
    
    # Calculate age in days
    current_time=$(date '+%s')
    age_days=$(( (current_time - mod_time) / 86400 ))
    
    # Relative path for display
    rel_path="${file#$PROJECT_ROOT/}"
    
    if [[ $age_days -gt $STALENESS_DAYS ]]; then
        STALE_FILES+=("$rel_path|$mod_date|$age_days")
    else
        FRESH_FILES+=("$rel_path|$mod_date|$age_days")
    fi
done < <(find "$CONTEXT_DIR" -name "*.md" -type f 2>/dev/null)

# Summary
log "${CYAN}Summary:${NC}"
log "  Total context files: $TOTAL_FILES"
log "  ${GREEN}Fresh (<${STALENESS_DAYS}d):${NC} ${#FRESH_FILES[@]}"
log "  ${YELLOW}Stale (>${STALENESS_DAYS}d):${NC} ${#STALE_FILES[@]}"
echo ""

if [[ ${#STALE_FILES[@]} -eq 0 ]]; then
    log "${GREEN}[PASS]${NC} All context files are fresh!"
    exit 0
fi

# Show stale files
log "${YELLOW}Stale Files (need review):${NC}"
echo ""
printf "%-60s %-12s %s\n" "File" "Modified" "Age"
printf "%-60s %-12s %s\n" "------------------------------------------------------------" "------------" "----"

# Sort by age (oldest first)
IFS=$'\n' sorted=($(printf '%s\n' "${STALE_FILES[@]}" | sort -t'|' -k3 -rn))

for entry in "${sorted[@]}"; do
    IFS='|' read -r file mod_date age_days <<< "$entry"
    
    # Color code by age
    if [[ $age_days -gt 180 ]]; then
        color=$RED
        indicator="[X]"
    elif [[ $age_days -gt 120 ]]; then
        color=$YELLOW
        indicator="[!]"
    else
        color=$CYAN
        indicator="[~]"
    fi
    
    printf "${color}%-60s %-12s %s days${NC}\n" "${file:0:60}" "$mod_date" "$age_days"
done

echo ""

# Recommendations
log "${BLUE}Recommendations:${NC}"
log "  Files >180 days [X]: Consider archiving or updating"
log "  Files >120 days [!]: Review for accuracy"
log "  Files >90 days [~]: Quick check if still relevant"
echo ""

# Cross-reference check (optional)
log "${BLUE}Cross-Reference Check:${NC}"
BROKEN_REFS=0
for entry in "${sorted[@]}"; do
    IFS='|' read -r file mod_date age_days <<< "$entry"
    full_path="$PROJECT_ROOT/$file"
    
    # Check for @ references in the file
    while IFS= read -r ref; do
        # Extract path from @reference
        ref_path=$(echo "$ref" | sed 's/@//' | sed 's/[[:space:]].*//')
        ref_full="$PROJECT_ROOT/$ref_path"
        
        if [[ ! -f "$ref_full" ]] && [[ ! -d "$ref_full" ]]; then
            if [[ $BROKEN_REFS -eq 0 ]]; then
                log "${YELLOW}Broken references found:${NC}"
            fi
            log "  ${RED}✗${NC} $file → @$ref_path"
            BROKEN_REFS=$((BROKEN_REFS + 1))
        fi
    done < <(grep -oE '@[a-zA-Z0-9_./-]+' "$full_path" 2>/dev/null || true)
done

if [[ $BROKEN_REFS -eq 0 ]]; then
    log "  ${GREEN}✓${NC} No broken @ references detected"
fi

echo ""
log "Analysis complete. Review stale files and update as needed."

#!/bin/bash
# Script: audit-log-query.sh
# Purpose: Query and filter Claude Code audit logs
# Usage: ./audit-log-query.sh [filters]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -uo pipefail

# Configuration
AIPROJECTS_DIR="${HOME}/AIProjects"
AUDIT_LOG="${AIPROJECTS_DIR}/.claude/logs/audit.jsonl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Query and filter Claude Code audit logs.

Options:
    -t, --tool TOOL     Filter by tool name (e.g., Bash, Read, Edit)
    -s, --session NAME  Filter by session name
    -n, --lines N       Show last N entries (default: 20)
    -d, --date DATE     Filter by date (YYYY-MM-DD)
    -j, --json          Raw JSON output
    -c, --count         Show count only
    --today             Filter to today's entries
    --errors            Show only errors
    -h, --help          Show this help

Examples:
    $(basename "$0")                      # Last 20 entries
    $(basename "$0") --tool Bash          # Bash commands only
    $(basename "$0") --session "Dev"      # Specific session
    $(basename "$0") --today --count      # Today's count
    $(basename "$0") -n 50 -t Edit        # Last 50 Edit operations

Output Columns:
    TIME     - Timestamp (HH:MM:SS)
    SESSION  - Session name
    TOOL     - Tool used
    SUMMARY  - Brief description

Exit Codes:
    0  Success
    1  Invalid arguments
    2  Log file not found
EOF
}

# Logging
log_info() { echo -e "${BLUE}ℹ${NC} $1" >&2; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Parse arguments
TOOL_FILTER=""
SESSION_FILTER=""
LINES=20
DATE_FILTER=""
JSON_OUTPUT=false
COUNT_ONLY=false
TODAY=false
ERRORS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -t|--tool) TOOL_FILTER="$2"; shift 2 ;;
        -s|--session) SESSION_FILTER="$2"; shift 2 ;;
        -n|--lines) LINES="$2"; shift 2 ;;
        -d|--date) DATE_FILTER="$2"; shift 2 ;;
        -j|--json) JSON_OUTPUT=true; shift ;;
        -c|--count) COUNT_ONLY=true; shift ;;
        --today) TODAY=true; DATE_FILTER=$(date +%Y-%m-%d); shift ;;
        --errors) ERRORS_ONLY=true; shift ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *) shift ;;
    esac
done

# Check log file exists
if [[ ! -f "$AUDIT_LOG" ]]; then
    log_error "Audit log not found: $AUDIT_LOG"
    echo "No audit log file. Logs are created by the audit-logger.js hook."
    exit 2
fi

# Build jq filter
JQ_FILTER="."

if [[ -n "$TOOL_FILTER" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.tool == \"$TOOL_FILTER\" or .tool == null)"
fi

if [[ -n "$SESSION_FILTER" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.session | contains(\"$SESSION_FILTER\"))"
fi

if [[ -n "$DATE_FILTER" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.timestamp | startswith(\"$DATE_FILTER\"))"
fi

if [[ "$ERRORS_ONLY" == true ]]; then
    JQ_FILTER="$JQ_FILTER | select(.type == \"error\" or .error != null)"
fi

# Count only
if [[ "$COUNT_ONLY" == true ]]; then
    COUNT=$(jq -s "[ .[] | $JQ_FILTER ] | length" "$AUDIT_LOG" 2>/dev/null || echo "0")
    echo "$COUNT"
    exit 0
fi

# JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
    tail -n "$LINES" "$AUDIT_LOG" | jq -s "[ .[] | $JQ_FILTER ]" 2>/dev/null
    exit 0
fi

# Formatted output
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                         AUDIT LOG QUERY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"

# Show active filters
FILTERS=""
[[ -n "$TOOL_FILTER" ]] && FILTERS="$FILTERS tool=$TOOL_FILTER"
[[ -n "$SESSION_FILTER" ]] && FILTERS="$FILTERS session=$SESSION_FILTER"
[[ -n "$DATE_FILTER" ]] && FILTERS="$FILTERS date=$DATE_FILTER"
[[ "$ERRORS_ONLY" == true ]] && FILTERS="$FILTERS errors-only"

if [[ -n "$FILTERS" ]]; then
    echo -e "${BLUE}Filters:${NC}$FILTERS"
fi
echo -e "${BLUE}Showing:${NC} last $LINES entries"
echo ""

# Header
printf "${YELLOW}%-10s %-20s %-12s %s${NC}\n" "TIME" "SESSION" "TOOL" "SUMMARY"
echo "─────────────────────────────────────────────────────────────────────────"

# Process entries
tail -n "$LINES" "$AUDIT_LOG" | while read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Parse JSON
    TIMESTAMP=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)
    SESSION=$(echo "$line" | jq -r '.session // "unknown"' 2>/dev/null)
    TOOL=$(echo "$line" | jq -r '.tool // .type // "unknown"' 2>/dev/null)

    # Apply filters
    if [[ -n "$TOOL_FILTER" ]] && [[ "$TOOL" != "$TOOL_FILTER" ]]; then
        continue
    fi

    if [[ -n "$SESSION_FILTER" ]] && [[ ! "$SESSION" =~ $SESSION_FILTER ]]; then
        continue
    fi

    if [[ -n "$DATE_FILTER" ]] && [[ ! "$TIMESTAMP" =~ ^$DATE_FILTER ]]; then
        continue
    fi

    # Extract time portion
    TIME=$(echo "$TIMESTAMP" | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
    [[ -z "$TIME" ]] && TIME="--:--:--"

    # Truncate session name
    SESSION="${SESSION:0:18}"

    # Get summary based on tool type
    case "$TOOL" in
        Bash)
            SUMMARY=$(echo "$line" | jq -r '.parameters.command // ""' 2>/dev/null | head -c 40)
            ;;
        Read|Write|Edit)
            SUMMARY=$(echo "$line" | jq -r '.parameters.file_path // .parameters.path // ""' 2>/dev/null | xargs basename 2>/dev/null)
            ;;
        *)
            SUMMARY=$(echo "$line" | jq -r '.type // ""' 2>/dev/null)
            ;;
    esac

    # Truncate summary
    SUMMARY="${SUMMARY:0:40}"

    # Color based on tool
    case "$TOOL" in
        Bash) TOOL_COLOR="${YELLOW}${TOOL}${NC}" ;;
        Edit|Write) TOOL_COLOR="${GREEN}${TOOL}${NC}" ;;
        Read) TOOL_COLOR="${BLUE}${TOOL}${NC}" ;;
        *) TOOL_COLOR="$TOOL" ;;
    esac

    printf "%-10s %-20s %-12b %s\n" "$TIME" "$SESSION" "$TOOL_COLOR" "$SUMMARY"
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"

# Show log location
echo -e "${BLUE}Log file:${NC} $AUDIT_LOG"
TOTAL=$(wc -l < "$AUDIT_LOG" 2>/dev/null || echo "0")
echo -e "${BLUE}Total entries:${NC} $TOTAL"
echo ""

exit 0

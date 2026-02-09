#!/usr/bin/env bash
# File Usage Tracker — AC-07 R&D internal research support
# Logs file access patterns for efficiency analysis
# Usage: ./file-usage-tracker.sh <file_path> [action]
# bash 3.2 compatible (macOS)

LOG_FILE="/Users/aircannon/Claude/Jarvis/.claude/logs/file-usage.jsonl"

track_usage() {
    local file_path="$1"
    local action="${2:-read}"
    local timestamp
    timestamp=$(date +%s)
    local iso_date
    iso_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"

    # Append JSONL entry using jq --arg for safe JSON (no string interpolation)
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg ts "$iso_date" --arg epoch "$timestamp" --arg fp "$file_path" --arg act "$action" \
            '{timestamp: $ts, epoch: ($epoch | tonumber), file: $fp, action: $act}' >> "$LOG_FILE"
    else
        # Fallback without jq
        printf '{"timestamp":"%s","epoch":%s,"file":"%s","action":"%s"}\n' \
            "$iso_date" "$timestamp" "$file_path" "$action" >> "$LOG_FILE"
    fi
    return 0
}

# If called directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ -z "$1" ]; then
        echo "Usage: $0 <file_path> [action]"
        exit 0
    fi
    track_usage "$1" "$2"
fi

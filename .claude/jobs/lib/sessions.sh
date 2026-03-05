#!/bin/bash
# sessions.sh — Session management for headless Claude agent
#
# Stores session history as JSONL files in .claude/jobs/sessions/
# Each session tracks the conversation between the user (Claude Desktop)
# and the headless Claude agent across multiple interactions.
#
# Usage:
#   source sessions.sh
#   session_get_history "session-abc123" 20
#   session_append "session-abc123" "user" "Check my Docker containers" "agent-infra-check"
#   session_cleanup 24

# Auto-detect project root (two levels up from lib/)
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

SESSIONS_DIR="${SESSIONS_DIR:-${PROJECT_DIR}/.claude/jobs/sessions}"

# Ensure sessions directory exists
session_init() {
    mkdir -p "$SESSIONS_DIR"
}

# Get formatted session history for prompt injection
# Args: session_id [max_entries]
# Output: Formatted conversation history or empty string
session_get_history() {
    local session_id="$1"
    local max_entries="${2:-20}"
    local session_file="$SESSIONS_DIR/${session_id}.jsonl"

    if [ ! -f "$session_file" ]; then
        echo ""
        return
    fi

    local history=""
    local count=0
    while IFS= read -r line; do
        local role content capability ts
        role=$(echo "$line" | jq -r '.role // ""' 2>/dev/null)
        content=$(echo "$line" | jq -r '.content // ""' 2>/dev/null)
        capability=$(echo "$line" | jq -r '.capability // ""' 2>/dev/null)
        ts=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)

        if [ -z "$role" ] || [ -z "$content" ]; then
            continue
        fi

        count=$((count + 1))
        local cap_label=""
        [ -n "$capability" ] && [ "$capability" != "null" ] && cap_label=" ($capability)"

        if [ "$role" = "user" ]; then
            history="${history}[${count}] User${cap_label}: ${content}\n"
        elif [ "$role" = "assistant" ]; then
            # Truncate long assistant responses in history
            local truncated="$content"
            if [ ${#content} -gt 500 ]; then
                truncated="${content:0:497}..."
            fi
            history="${history}[${count}] Agent${cap_label}: ${truncated}\n"
        fi
    done < <(tail -n "$((max_entries * 2))" "$session_file")

    echo -e "$history"
}

# Get session metadata (creation time, interaction count, last capability)
# Args: session_id
# Output: JSON object with metadata
session_metadata() {
    local session_id="$1"
    local session_file="$SESSIONS_DIR/${session_id}.jsonl"

    if [ ! -f "$session_file" ]; then
        echo '{"exists":false}'
        return
    fi

    local line_count
    line_count=$(wc -l < "$session_file")
    local first_ts
    first_ts=$(head -1 "$session_file" | jq -r '.timestamp // "unknown"' 2>/dev/null)
    local last_ts
    last_ts=$(tail -1 "$session_file" | jq -r '.timestamp // "unknown"' 2>/dev/null)
    local last_cap
    last_cap=$(tail -1 "$session_file" | jq -r '.capability // "unknown"' 2>/dev/null)

    jq -nc \
        --argjson exists true \
        --arg sid "$session_id" \
        --argjson count "$line_count" \
        --arg first "$first_ts" \
        --arg last "$last_ts" \
        --arg cap "$last_cap" \
        '{exists:$exists, session_id:$sid, interactions:$count, created:$first, last_active:$last, last_capability:$cap}'
}

# Append an interaction to session history
# Args: session_id role content [capability]
session_append() {
    local session_id="$1"
    local role="$2"
    local content="$3"
    local capability="${4:-}"

    session_init

    local session_file="$SESSIONS_DIR/${session_id}.jsonl"

    jq -nc \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg role "$role" \
        --arg content "$content" \
        --arg cap "$capability" \
        '{timestamp:$ts, role:$role, content:$content, capability:$cap}' \
        >> "$session_file"
}

# Clean up expired sessions
# Args: [max_age_hours] (default: 24)
session_cleanup() {
    local max_age_hours="${1:-24}"
    session_init
    local deleted=0
    while IFS= read -r -d '' file; do
        rm -f "$file"
        deleted=$((deleted + 1))
    done < <(find "$SESSIONS_DIR" -name "*.jsonl" -mmin "+$((max_age_hours * 60))" -print0 2>/dev/null)
    [ "$deleted" -gt 0 ] && echo "Cleaned up $deleted expired sessions"
}

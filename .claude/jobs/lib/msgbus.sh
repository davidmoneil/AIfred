#!/bin/bash
# msgbus.sh - Unified message bus CLI for Headless Claude
#
# Append-only event store in messages.jsonl with sequential IDs,
# threading (parent_id/thread_id), and jq-based queries.
#
# Usage:
#   msgbus.sh send --type job_completed --source "headless:health-summary" \
#     --severity info --data '{"job":"health-summary","summary":"All healthy"}'
#   msgbus.sh query --type question_asked --status pending
#   msgbus.sh reply --parent 42 --type question_answered \
#     --source "telegram:david" --data '{"answer":"approve"}'
#   msgbus.sh pending
#   msgbus.sh deliver --id 42 --by relay
#   msgbus.sh thread 42
#   msgbus.sh state

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
MESSAGES_FILE="$JOBS_DIR/messages.jsonl"
CURSOR_FILE="$JOBS_DIR/state/msgbus-cursor.txt"
LOCK_FILE="$JOBS_DIR/state/msgbus-cursor.lock"

# ============================================================================
# Helpers
# ============================================================================

# Get next sequential ID (atomic via flock)
next_id() {
    local id
    (
        flock -w 5 200 || { echo "ERROR: Could not acquire cursor lock" >&2; exit 1; }
        if [ ! -f "$CURSOR_FILE" ]; then
            echo "0" > "$CURSOR_FILE"
        fi
        id=$(cat "$CURSOR_FILE")
        id=$((id + 1))
        echo "$id" > "$CURSOR_FILE"
        echo "$id"
    ) 200>"$LOCK_FILE"
}

# ISO 8601 UTC timestamp
now_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Ensure messages file exists
ensure_store() {
    mkdir -p "$(dirname "$MESSAGES_FILE")"
    mkdir -p "$(dirname "$CURSOR_FILE")"
    touch "$MESSAGES_FILE"
}

# ============================================================================
# Subcommands
# ============================================================================

# --- send ---
# Write an event to the bus. Returns the event ID.
cmd_send() {
    local event_type="" source="" severity="info" data="{}" parent_id="null" deliver_after="" expires_at="null" job=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --type|-t) event_type="$2"; shift 2 ;;
            --source|-s) source="$2"; shift 2 ;;
            --severity) severity="$2"; shift 2 ;;
            --data|-d) data="$2"; shift 2 ;;
            --parent) parent_id="$2"; shift 2 ;;
            --deliver-after) deliver_after="$2"; shift 2 ;;
            --expires) expires_at="$2"; shift 2 ;;
            --job|-j) job="$2"; shift 2 ;;
            *) echo "ERROR: Unknown send option: $1" >&2; return 1 ;;
        esac
    done

    if [ -z "$event_type" ]; then
        echo "ERROR: --type is required" >&2
        return 1
    fi
    if [ -z "$source" ]; then
        echo "ERROR: --source is required" >&2
        return 1
    fi

    ensure_store

    local id
    id=$(next_id)
    local ts
    ts=$(now_utc)

    # Resolve deliver_after: support relative offsets like "+30min", "+24h", "+7d"
    local da="$ts"
    if [ -n "$deliver_after" ]; then
        da=$(resolve_time "$deliver_after")
    fi

    # Resolve expires_at
    local exp="null"
    if [ "$expires_at" != "null" ] && [ -n "$expires_at" ]; then
        exp="\"$(resolve_time "$expires_at")\""
    fi

    # Threading: if replying to a parent, inherit thread_id
    local thread_id="null"
    if [ "$parent_id" != "null" ]; then
        # Look up parent's thread_id; if null, the parent is the thread root
        local parent_thread
        parent_thread=$(jq -r "select(.id == $parent_id) | .thread_id // .id" "$MESSAGES_FILE" 2>/dev/null | head -1)
        if [ -n "$parent_thread" ] && [ "$parent_thread" != "null" ]; then
            thread_id="$parent_thread"
        else
            thread_id="$parent_id"
        fi
    fi

    # Inject job into data if provided and not already present
    if [ -n "$job" ]; then
        data=$(echo "$data" | jq --arg j "$job" '. + {job: $j}')
    fi

    local record
    record=$(jq -nc \
        --argjson id "$id" \
        --arg event_type "$event_type" \
        --arg source "$source" \
        --arg actor "$(whoami 2>/dev/null || echo executor)" \
        --arg severity "$severity" \
        --argjson parent_id "$parent_id" \
        --argjson thread_id "$thread_id" \
        --arg status "pending" \
        --argjson data "$data" \
        --arg created_at "$ts" \
        --arg deliver_after "$da" \
        --argjson expires_at "$exp" \
        '{
            id: $id,
            event_type: $event_type,
            source: $source,
            actor: $actor,
            severity: $severity,
            parent_id: $parent_id,
            thread_id: $thread_id,
            status: $status,
            data: $data,
            created_at: $created_at,
            deliver_after: $deliver_after,
            expires_at: $expires_at
        }')

    echo "$record" >> "$MESSAGES_FILE"
    echo "$id"
}

# --- reply ---
# Convenience wrapper: send with --parent auto-setting thread_id
cmd_reply() {
    local parent_id="" event_type="" source="" data="{}" severity=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --parent|-p) parent_id="$2"; shift 2 ;;
            --type|-t) event_type="$2"; shift 2 ;;
            --source|-s) source="$2"; shift 2 ;;
            --data|-d) data="$2"; shift 2 ;;
            --severity) severity="$2"; shift 2 ;;
            *) echo "ERROR: Unknown reply option: $1" >&2; return 1 ;;
        esac
    done

    if [ -z "$parent_id" ]; then
        echo "ERROR: --parent is required for reply" >&2
        return 1
    fi

    # Inherit severity from parent if not specified
    if [ -z "$severity" ]; then
        severity=$(jq -r "select(.id == $parent_id) | .severity" "$MESSAGES_FILE" 2>/dev/null | head -1)
        severity="${severity:-info}"
    fi

    cmd_send --type "${event_type:-user_response}" --source "${source:-unknown}" \
        --severity "$severity" --data "$data" --parent "$parent_id"
}

# --- query ---
# Filter events by type, status, severity, job, since
cmd_query() {
    local filter="true"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --type|-t) filter="$filter and .event_type == \"$2\""; shift 2 ;;
            --status) filter="$filter and .status == \"$2\""; shift 2 ;;
            --severity) filter="$filter and .severity == \"$2\""; shift 2 ;;
            --job|-j) filter="$filter and (.data.job // \"\") == \"$2\""; shift 2 ;;
            --since) filter="$filter and .created_at >= \"$2\""; shift 2 ;;
            --id) filter="$filter and .id == $2"; shift 2 ;;
            --limit|-n) ;; # handled below
            *) echo "ERROR: Unknown query option: $1" >&2; return 1 ;;
        esac
    done

    ensure_store
    jq -c "select($filter)" "$MESSAGES_FILE"
}

# --- pending ---
# Show undelivered messages where deliver_after <= now
cmd_pending() {
    ensure_store
    local now
    now=$(now_utc)
    jq -c "select(.status == \"pending\" and .deliver_after <= \"$now\")" "$MESSAGES_FILE"
}

# --- deliver ---
# Mark a message as delivered (append a delivery event)
cmd_deliver() {
    local msg_id="" delivered_by="relay"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --id) msg_id="$2"; shift 2 ;;
            --by) delivered_by="$2"; shift 2 ;;
            *) echo "ERROR: Unknown deliver option: $1" >&2; return 1 ;;
        esac
    done

    if [ -z "$msg_id" ]; then
        echo "ERROR: --id is required" >&2
        return 1
    fi

    ensure_store

    # Append a delivery event and update the original message status in-place
    # Event sourcing: append a notification_delivered event
    local id
    id=$(next_id)
    local ts
    ts=$(now_utc)

    local record
    record=$(jq -nc \
        --argjson id "$id" \
        --arg event_type "notification_delivered" \
        --arg source "relay:$delivered_by" \
        --arg actor "$delivered_by" \
        --arg severity "info" \
        --argjson parent_id "$msg_id" \
        --arg status "delivered" \
        --arg created_at "$ts" \
        --arg deliver_after "$ts" \
        '{
            id: $id,
            event_type: $event_type,
            source: $source,
            actor: $actor,
            severity: $severity,
            parent_id: $parent_id,
            thread_id: null,
            status: $status,
            data: {},
            created_at: $created_at,
            deliver_after: $deliver_after,
            expires_at: null
        }')

    echo "$record" >> "$MESSAGES_FILE"

    # Also update original message status (sed in-place for the specific line)
    # This is a pragmatic choice: we keep event sourcing purity (the delivery event)
    # but also mark the original for efficient pending queries
    local tmp
    tmp=$(mktemp)
    jq -c "if .id == $msg_id then .status = \"delivered\" else . end" "$MESSAGES_FILE" > "$tmp" \
        && mv "$tmp" "$MESSAGES_FILE"
}

# --- thread ---
# Show full conversation thread for a given message ID
cmd_thread() {
    local root_id="$1"

    if [ -z "$root_id" ]; then
        echo "ERROR: thread requires a message ID" >&2
        return 1
    fi

    ensure_store

    # Find the thread root: check if this message has a thread_id
    local thread_root
    thread_root=$(jq -r "select(.id == $root_id) | .thread_id // \"null\"" "$MESSAGES_FILE" 2>/dev/null | head -1)

    if [ "$thread_root" = "null" ] || [ -z "$thread_root" ]; then
        # This message IS the root
        thread_root="$root_id"
    fi

    # Return the root message + all messages in this thread
    jq -c "select(.id == $thread_root or .thread_id == $thread_root)" "$MESSAGES_FILE"
}

# --- state ---
# Reconstruct current state summary: pending questions, undelivered messages, due reminders
cmd_state() {
    ensure_store
    local now
    now=$(now_utc)

    echo "=== Message Bus State ==="
    echo ""

    # Pending questions
    local pending_q
    pending_q=$(jq -c 'select(.event_type == "question_asked" and .status == "pending")' "$MESSAGES_FILE" 2>/dev/null | wc -l)
    echo "Pending questions: $pending_q"
    if [ "$pending_q" -gt 0 ]; then
        jq -r 'select(.event_type == "question_asked" and .status == "pending") | "  [\(.id)] \(.data.job // "unknown"): \(.data.question // .data.summary // "?")"' "$MESSAGES_FILE" 2>/dev/null
    fi
    echo ""

    # Undelivered messages ready now
    local undelivered
    undelivered=$(jq -c "select(.status == \"pending\" and .deliver_after <= \"$now\")" "$MESSAGES_FILE" 2>/dev/null | wc -l)
    echo "Undelivered (ready): $undelivered"
    echo ""

    # Due reminders
    local reminders
    reminders=$(jq -c "select(.event_type == \"reminder_due\" and .status == \"pending\" and .deliver_after <= \"$now\")" "$MESSAGES_FILE" 2>/dev/null | wc -l)
    echo "Due reminders: $reminders"
    echo ""

    # Total events
    local total
    total=$(wc -l < "$MESSAGES_FILE" 2>/dev/null || echo "0")
    echo "Total events: $total"

    # Last event
    if [ "$total" -gt 0 ]; then
        local last
        last=$(tail -1 "$MESSAGES_FILE" | jq -r '"  Last: [\(.id)] \(.event_type) from \(.source) at \(.created_at)"' 2>/dev/null)
        echo "$last"
    fi
}

# --- health ---
# Check message bus health: stuck messages, file size, cursor integrity
cmd_health() {
    ensure_store
    local now issues=0
    now=$(now_utc)

    echo "=== Message Bus Health ==="
    echo ""

    # 1. File size check
    local file_size_bytes=0
    if [ -f "$MESSAGES_FILE" ]; then
        file_size_bytes=$(stat -c%s "$MESSAGES_FILE" 2>/dev/null || echo "0")
    fi
    local file_size_kb=$((file_size_bytes / 1024))
    local file_size_mb=$((file_size_bytes / 1048576))
    local total_events
    total_events=$(wc -l < "$MESSAGES_FILE" 2>/dev/null || echo "0")

    if [ "$file_size_bytes" -gt 10485760 ]; then
        echo "[!] Store size: ${file_size_mb}MB (${total_events} events) — consider archiving"
        issues=$((issues + 1))
    elif [ "$file_size_bytes" -gt 5242880 ]; then
        echo "[~] Store size: ${file_size_mb}MB (${total_events} events) — growing"
        issues=$((issues + 1))
    else
        echo "[ok] Store size: ${file_size_kb}KB (${total_events} events)"
    fi

    # 2. Cursor integrity
    if [ -f "$CURSOR_FILE" ]; then
        local cursor_val
        cursor_val=$(cat "$CURSOR_FILE" 2>/dev/null)
        if [[ "$cursor_val" =~ ^[0-9]+$ ]]; then
            echo "[ok] Cursor: $cursor_val (valid)"
        else
            echo "[!] Cursor: '$cursor_val' — NOT a valid integer"
            issues=$((issues + 1))
        fi
    else
        echo "[!] Cursor file missing: $CURSOR_FILE"
        issues=$((issues + 1))
    fi

    # 3. Stuck pending messages (pending for >2 hours)
    local two_hours_ago
    two_hours_ago=$(date -u -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    local stuck_count=0
    local stuck_details=""
    if [ "$total_events" -gt 0 ]; then
        stuck_count=$(jq -c "select(.status == \"pending\" and .deliver_after <= \"$two_hours_ago\")" "$MESSAGES_FILE" 2>/dev/null | wc -l)
        if [ "$stuck_count" -gt 0 ]; then
            stuck_details=$(jq -r "select(.status == \"pending\" and .deliver_after <= \"$two_hours_ago\") | \"  [\(.id)] \(.event_type) \(.severity) since \(.created_at)\"" "$MESSAGES_FILE" 2>/dev/null)
        fi
    fi

    if [ "$stuck_count" -gt 0 ]; then
        echo "[!] Stuck pending: $stuck_count messages older than 2h"
        echo "$stuck_details"
        issues=$((issues + 1))
    else
        echo "[ok] No stuck messages"
    fi

    # 4. Unanswered questions (pending for >4 hours)
    local four_hours_ago
    four_hours_ago=$(date -u -d "-4 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    local stale_questions=0
    if [ "$total_events" -gt 0 ]; then
        stale_questions=$(jq -c "select(.event_type == \"question_asked\" and .status == \"pending\" and .created_at <= \"$four_hours_ago\")" "$MESSAGES_FILE" 2>/dev/null | wc -l)
    fi

    if [ "$stale_questions" -gt 0 ]; then
        echo "[~] Unanswered questions: $stale_questions (>4h old)"
        jq -r "select(.event_type == \"question_asked\" and .status == \"pending\" and .created_at <= \"$four_hours_ago\") | \"  [\(.id)] \(.data.job // \"?\"): \(.data.question // \"?\") (since \(.created_at))\"" "$MESSAGES_FILE" 2>/dev/null
        issues=$((issues + 1))
    else
        echo "[ok] No stale questions"
    fi

    # 5. JSONL integrity (spot check: last line is valid JSON)
    if [ "$total_events" -gt 0 ]; then
        if tail -1 "$MESSAGES_FILE" | jq . > /dev/null 2>&1; then
            echo "[ok] JSONL integrity: last record valid"
        else
            echo "[!] JSONL integrity: last record is INVALID JSON"
            issues=$((issues + 1))
        fi
    fi

    # Summary
    echo ""
    if [ "$issues" -eq 0 ]; then
        echo "Status: HEALTHY"
    else
        echo "Status: $issues issue(s) found"
    fi

    return "$issues"
}

# ============================================================================
# Time Resolution Helper
# ============================================================================

# Resolve relative time offsets to absolute ISO 8601 UTC timestamps
# Supports: "+30min", "+1h", "+24h", "+7d", or absolute ISO timestamps
resolve_time() {
    local input="$1"

    # Already an ISO timestamp?
    if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
        echo "$input"
        return
    fi

    # Relative offset: +Nmin, +Nh, +Nd
    if [[ "$input" =~ ^\+([0-9]+)(min|h|d)$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        local secs=0
        case "$unit" in
            min) secs=$((num * 60)) ;;
            h)   secs=$((num * 3600)) ;;
            d)   secs=$((num * 86400)) ;;
        esac
        date -u -d "+${secs} seconds" +%Y-%m-%dT%H:%M:%SZ
        return
    fi

    # Fallback: try GNU date parsing
    date -u -d "$input" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$input"
}

# ============================================================================
# Main
# ============================================================================

if [ $# -lt 1 ]; then
    cat << 'EOF'
msgbus.sh - Headless Claude Message Bus

USAGE:
    msgbus.sh <command> [options]

COMMANDS:
    send      Write an event to the bus
    reply     Reply to a message (auto-threads)
    query     Filter events by criteria
    pending   Show undelivered messages ready for sending
    deliver   Mark a message as delivered
    thread    Show full conversation thread
    state     Show current bus state summary
    health    Check bus health (stuck messages, file size, cursor)

EXAMPLES:
    msgbus.sh send --type job_completed --source "headless:health" --severity info \
      --data '{"job":"health","summary":"All OK"}'
    msgbus.sh query --type question_asked --status pending
    msgbus.sh reply --parent 42 --type question_answered --source "telegram:david" \
      --data '{"answer":"approve"}'
    msgbus.sh pending
    msgbus.sh deliver --id 42 --by relay
    msgbus.sh thread 42
    msgbus.sh state
EOF
    exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
    send)    cmd_send "$@" ;;
    reply)   cmd_reply "$@" ;;
    query)   cmd_query "$@" ;;
    pending) cmd_pending "$@" ;;
    deliver) cmd_deliver "$@" ;;
    thread)  cmd_thread "$@" ;;
    state)   cmd_state "$@" ;;
    health)  cmd_health "$@" ;;
    *)
        echo "ERROR: Unknown command: $COMMAND" >&2
        echo "Run 'msgbus.sh' without arguments for help." >&2
        exit 1
        ;;
esac

#!/bin/bash
# msgbus.sh - Unified message bus CLI
#
# SQLite-backed event store with sequential IDs (AUTOINCREMENT),
# threading (parent_id/thread_id), and indexed queries.
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
JOBSDB="$SCRIPT_DIR/jobsdb.py"

# Helper: run SQL
_db() {
    python3 "$JOBSDB" "$@"
}

# ============================================================================
# Helpers
# ============================================================================

# ISO 8601 UTC timestamp
now_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# ============================================================================
# Subcommands
# ============================================================================

# --- send ---
# Write an event to the bus. Returns the event ID.
cmd_send() {
    local event_type="" source="" severity="info" data="{}" parent_id="" deliver_after="" expires_at="" job=""

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

    local ts
    ts=$(now_utc)

    # Resolve deliver_after: support relative offsets like "+30min", "+24h", "+7d"
    local da="$ts"
    if [ -n "$deliver_after" ]; then
        da=$(resolve_time "$deliver_after")
    fi

    # Resolve expires_at
    local exp=""
    if [ -n "$expires_at" ]; then
        exp=$(resolve_time "$expires_at")
    fi

    # Threading: if replying to a parent, inherit thread_id
    local thread_id=""
    if [ -n "$parent_id" ]; then
        local parent_thread
        parent_thread=$(_db exec-scalar \
            "SELECT COALESCE(thread_id, id) FROM events WHERE id = ?" \
            "$parent_id")
        if [ -n "$parent_thread" ]; then
            thread_id="$parent_thread"
        else
            thread_id="$parent_id"
        fi
    fi

    # Inject job into data if provided and not already present
    if [ -n "$job" ]; then
        data=$(echo "$data" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'job' not in d:
    d['job'] = '$job'
print(json.dumps(d))
")
    fi

    local actor
    actor=$(whoami 2>/dev/null || echo executor)

    # Insert and return the new ID (AUTOINCREMENT handles sequencing)
    _db insert \
        "INSERT INTO events (event_type, source, actor, severity, parent_id, thread_id, status, data, created_at, deliver_after, expires_at) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?)" \
        "$event_type" "$source" "$actor" "$severity" \
        "${parent_id:-}" "${thread_id:-}" \
        "$data" "$ts" "$da" "${exp:-}"
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
        severity=$(_db exec-scalar \
            "SELECT severity FROM events WHERE id = ?" "$parent_id")
        severity="${severity:-info}"
    fi

    cmd_send --type "${event_type:-user_response}" --source "${source:-unknown}" \
        --severity "$severity" --data "$data" --parent "$parent_id"
}

# --- query ---
# Filter events by type, status, severity, job, since
cmd_query() {
    local wheres=() params=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --type|-t) wheres+=("event_type = ?"); params+=("$2"); shift 2 ;;
            --status) wheres+=("status = ?"); params+=("$2"); shift 2 ;;
            --severity) wheres+=("severity = ?"); params+=("$2"); shift 2 ;;
            --job|-j) wheres+=("json_extract(data, '$.job') = ?"); params+=("$2"); shift 2 ;;
            --since) wheres+=("created_at >= ?"); params+=("$2"); shift 2 ;;
            --id) wheres+=("id = ?"); params+=("$2"); shift 2 ;;
            --limit|-n) ;; # handled below
            *) echo "ERROR: Unknown query option: $1" >&2; return 1 ;;
        esac
    done

    local sql="SELECT id, event_type, source, actor, severity, parent_id, thread_id, status, data, created_at, deliver_after, expires_at FROM events"
    if [ ${#wheres[@]} -gt 0 ]; then
        local where_clause=""
        for i in "${!wheres[@]}"; do
            [ "$i" -gt 0 ] && where_clause="$where_clause AND "
            where_clause="$where_clause${wheres[$i]}"
        done
        sql="$sql WHERE $where_clause"
    fi
    sql="$sql ORDER BY id"

    _db exec "$sql" "${params[@]}"
}

# --- pending ---
# Show undelivered messages where deliver_after <= now
cmd_pending() {
    local now
    now=$(now_utc)
    _db exec \
        "SELECT id, event_type, source, actor, severity, parent_id, thread_id, status, data, created_at, deliver_after, expires_at FROM events WHERE status = 'pending' AND deliver_after <= ? ORDER BY id" \
        "$now"
}

# --- deliver ---
# Mark a message as delivered (append a delivery event + update original)
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

    local ts
    ts=$(now_utc)

    # Insert delivery event and update original status atomically
    _db exec \
        "INSERT INTO events (event_type, source, actor, severity, parent_id, thread_id, status, data, created_at, deliver_after, expires_at) VALUES ('notification_delivered', ?, ?, 'info', ?, NULL, 'delivered', '{}', ?, ?, NULL)" \
        "relay:$delivered_by" "$delivered_by" "$msg_id" "$ts" "$ts"

    _db exec \
        "UPDATE events SET status = 'delivered' WHERE id = ?" \
        "$msg_id"
}

# --- thread ---
# Show full conversation thread for a given message ID
cmd_thread() {
    local root_id="$1"

    if [ -z "$root_id" ]; then
        echo "ERROR: thread requires a message ID" >&2
        return 1
    fi

    # Find the thread root
    local thread_root
    thread_root=$(_db exec-scalar \
        "SELECT COALESCE(thread_id, id) FROM events WHERE id = ?" "$root_id")
    thread_root="${thread_root:-$root_id}"

    # Return root + all messages in thread
    _db exec \
        "SELECT id, event_type, source, actor, severity, parent_id, thread_id, status, data, created_at, deliver_after, expires_at FROM events WHERE id = ? OR thread_id = ? ORDER BY id" \
        "$thread_root" "$thread_root"
}

# --- state ---
# Reconstruct current state summary
cmd_state() {
    local now
    now=$(now_utc)

    echo "=== Message Bus State ==="
    echo ""

    # Pending questions
    local pending_q
    pending_q=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE event_type = 'question_asked' AND status = 'pending'")
    echo "Pending questions: $pending_q"
    if [ "$pending_q" -gt 0 ]; then
        _db exec-raw \
            "SELECT id, json_extract(data, '$.job'), COALESCE(json_extract(data, '$.question'), json_extract(data, '$.summary'), '?') FROM events WHERE event_type = 'question_asked' AND status = 'pending'" | \
        while IFS=$'\t' read -r eid ejob equestion; do
            echo "  [$eid] ${ejob:-unknown}: $equestion"
        done
    fi
    echo ""

    # Undelivered messages ready now
    local undelivered
    undelivered=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE status = 'pending' AND deliver_after <= ?" "$now")
    echo "Undelivered (ready): $undelivered"
    echo ""

    # Due reminders
    local reminders
    reminders=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE event_type = 'reminder_due' AND status = 'pending' AND deliver_after <= ?" "$now")
    echo "Due reminders: $reminders"
    echo ""

    # Total events
    local total
    total=$(_db exec-scalar "SELECT COUNT(*) FROM events")
    echo "Total events: $total"

    # Last event
    if [ "$total" -gt 0 ]; then
        _db exec-raw \
            "SELECT id, event_type, source, created_at FROM events ORDER BY id DESC LIMIT 1" | \
        while IFS=$'\t' read -r eid etype esrc ecreated; do
            echo "  Last: [$eid] $etype from $esrc at $ecreated"
        done
    fi
}

# --- health ---
# Check message bus health
cmd_health() {
    local now issues=0
    now=$(now_utc)

    echo "=== Message Bus Health ==="
    echo ""

    # 1. Database size check
    local db_path
    db_path="$JOBS_DIR/state/jobs.db"
    local file_size_bytes=0
    if [ -f "$db_path" ]; then
        file_size_bytes=$(stat -c%s "$db_path" 2>/dev/null || echo "0")
    fi
    local file_size_kb=$((file_size_bytes / 1024))
    local file_size_mb=$((file_size_bytes / 1048576))
    local total_events
    total_events=$(_db exec-scalar "SELECT COUNT(*) FROM events")

    if [ "$file_size_bytes" -gt 10485760 ]; then
        echo "[!] Store size: ${file_size_mb}MB (${total_events} events) -- consider archiving"
        issues=$((issues + 1))
    elif [ "$file_size_bytes" -gt 5242880 ]; then
        echo "[~] Store size: ${file_size_mb}MB (${total_events} events) -- growing"
        issues=$((issues + 1))
    else
        echo "[ok] Store size: ${file_size_kb}KB (${total_events} events)"
    fi

    # 2. AUTOINCREMENT integrity
    local max_id
    max_id=$(_db exec-scalar "SELECT COALESCE(MAX(id), 0) FROM events")
    echo "[ok] Sequence: max_id=$max_id (AUTOINCREMENT)"

    # 3. Stuck pending messages (pending for >2 hours)
    local two_hours_ago
    two_hours_ago=$(date -u -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    local stuck_count
    stuck_count=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE status = 'pending' AND deliver_after <= ?" "$two_hours_ago")

    if [ "$stuck_count" -gt 0 ]; then
        echo "[!] Stuck pending: $stuck_count messages older than 2h"
        _db exec-raw \
            "SELECT id, event_type, severity, created_at FROM events WHERE status = 'pending' AND deliver_after <= ? ORDER BY id" \
            "$two_hours_ago" | \
        while IFS=$'\t' read -r eid etype esev ecreated; do
            echo "  [$eid] $etype $esev since $ecreated"
        done
        issues=$((issues + 1))
    else
        echo "[ok] No stuck messages"
    fi

    # 4. Unanswered questions (pending for >4 hours)
    local four_hours_ago
    four_hours_ago=$(date -u -d "-4 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    local stale_questions
    stale_questions=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE event_type = 'question_asked' AND status = 'pending' AND created_at <= ?" "$four_hours_ago")

    if [ "$stale_questions" -gt 0 ]; then
        echo "[~] Unanswered questions: $stale_questions (>4h old)"
        _db exec-raw \
            "SELECT id, json_extract(data, '$.job'), COALESCE(json_extract(data, '$.question'), '?'), created_at FROM events WHERE event_type = 'question_asked' AND status = 'pending' AND created_at <= ? ORDER BY id" \
            "$four_hours_ago" | \
        while IFS=$'\t' read -r eid ejob eq ecreated; do
            echo "  [$eid] ${ejob:-?}: $eq (since $ecreated)"
        done
        issues=$((issues + 1))
    else
        echo "[ok] No stale questions"
    fi

    # 5. SQLite integrity check
    local integrity
    integrity=$(_db pragma "PRAGMA integrity_check")
    if [ "$integrity" = "ok" ]; then
        echo "[ok] Database integrity: ok"
    else
        echo "[!] Database integrity: $integrity"
        issues=$((issues + 1))
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
msgbus.sh - Job Engine Message Bus

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
    health    Check bus health (stuck messages, DB size, integrity)

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

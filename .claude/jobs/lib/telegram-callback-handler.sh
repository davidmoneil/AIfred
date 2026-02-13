#!/bin/bash
# telegram-callback-handler.sh - Process Telegram button clicks and text replies
#
# Polls Telegram getUpdates API for callback_query (button presses) and
# text messages (free-text replies after "Other"). Writes responses to
# the message bus via msgbus.sh.
#
# Usage:
#   telegram-callback-handler.sh              # Single poll cycle
#   telegram-callback-handler.sh --daemon     # Continuous long-polling
#   telegram-callback-handler.sh --dry-run    # Show updates without processing
#
# Cron: */5 * * * * /path/to/telegram-callback-handler.sh

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$JOBS_DIR/.env"
MSGBUS="$SCRIPT_DIR/msgbus.sh"
STATE_DIR="$JOBS_DIR/state"
OFFSET_FILE="$STATE_DIR/telegram-update-offset.txt"
LOG_DIR="$JOBS_DIR/../../.claude/logs/headless"
HANDLER_LOG="$LOG_DIR/callback-handler.log"

# Polling timeout (seconds) for getUpdates
POLL_TIMEOUT=30

# ============================================================================
# Helpers
# ============================================================================

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HANDLER_LOG" 2>/dev/null; }

load_env() {
    if [ ! -f "$ENV_FILE" ]; then
        log "ERROR: $ENV_FILE not found"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
        log "ERROR: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in $ENV_FILE"
        exit 1
    fi
    API_BASE="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
}

get_offset() {
    if [ -f "$OFFSET_FILE" ]; then
        cat "$OFFSET_FILE"
    else
        echo "0"
    fi
}

save_offset() {
    echo "$1" > "$OFFSET_FILE"
}

# ============================================================================
# Telegram API Helpers
# ============================================================================

# Answer a callback query (removes the loading spinner on button press)
answer_callback_query() {
    local callback_query_id="$1"
    local text="${2:-}"
    curl -s -X POST "${API_BASE}/answerCallbackQuery" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc \
            --arg id "$callback_query_id" \
            --arg text "$text" \
            '{callback_query_id: $id, text: $text}')" \
        > /dev/null 2>&1 || true
}

# Edit an existing message's text (to show selection result)
edit_message_text() {
    local chat_id="$1"
    local message_id="$2"
    local new_text="$3"
    curl -s -X POST "${API_BASE}/editMessageText" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc \
            --arg chat_id "$chat_id" \
            --argjson message_id "$message_id" \
            --arg text "$new_text" \
            --arg parse_mode "HTML" \
            '{chat_id: $chat_id, message_id: $message_id, text: $text, parse_mode: $parse_mode}')" \
        > /dev/null 2>&1 || true
}

# ============================================================================
# Callback Data Parsing
# ============================================================================

# Find the most recent pending question for a job in the message bus
find_question_for_job() {
    local job="$1"
    "$MSGBUS" query --type question_asked --status pending --job "$job" 2>/dev/null \
        | jq -r '.id' 2>/dev/null | tail -1
}

# Parse text patterns for action commands
# Returns: action_type and optional time offset
parse_text_action() {
    local text="$1"
    local lower
    lower=$(echo "$text" | tr '[:upper:]' '[:lower:]' | xargs)

    # "remind 24h" / "remind 1h" / "remind 7d" / "remind tomorrow"
    if [[ "$lower" =~ ^remind[[:space:]]+(.+)$ ]]; then
        local time_spec="${BASH_REMATCH[1]}"
        case "$time_spec" in
            tomorrow)     echo "remind +24h" ;;
            *h|*d|*min)   echo "remind +${time_spec}" ;;
            "1 week"|"1w"|"a week") echo "remind +7d" ;;
            "1 day"|"1d"|"a day")   echo "remind +24h" ;;
            *)            echo "remind +24h" ;; # default to 24h
        esac
        return
    fi

    # "escalate" / "critical"
    if [[ "$lower" =~ ^(escalate|critical)$ ]]; then
        echo "escalate"
        return
    fi

    # "defer 3 days" / "defer 1 week"
    if [[ "$lower" =~ ^defer[[:space:]]+(.+)$ ]]; then
        local time_spec="${BASH_REMATCH[1]}"
        case "$time_spec" in
            *day*)  local num=$(echo "$time_spec" | grep -oP '\d+' | head -1); echo "defer +${num:-3}d" ;;
            *week*) local num=$(echo "$time_spec" | grep -oP '\d+' | head -1); echo "defer +$(( ${num:-1} * 7 ))d" ;;
            *)      echo "defer +3d" ;;
        esac
        return
    fi

    # Anything else = custom answer
    echo "custom"
}

# ============================================================================
# Update Processing
# ============================================================================

process_callback_query() {
    local update="$1"
    local callback_query_id callback_data chat_id message_id original_text job action

    callback_query_id=$(echo "$update" | jq -r '.callback_query.id')
    callback_data=$(echo "$update" | jq -r '.callback_query.data')
    chat_id=$(echo "$update" | jq -r '.callback_query.message.chat.id')
    message_id=$(echo "$update" | jq -r '.callback_query.message.message_id')
    original_text=$(echo "$update" | jq -r '.callback_query.message.text // ""')

    # Parse callback_data format: "job:action"
    job=$(echo "$callback_data" | cut -d: -f1)
    action=$(echo "$callback_data" | cut -d: -f2-)

    log "Callback: job=$job action=$action"

    # Find the corresponding question in the bus
    local question_id
    question_id=$(find_question_for_job "$job")

    if [ -z "$question_id" ] || [ "$question_id" = "null" ]; then
        answer_callback_query "$callback_query_id" "No pending question found for $job"
        log "WARNING: No pending question found for job=$job"
        return
    fi

    case "$action" in
        approve|deny|skip)
            # Direct answer — write to bus
            "$MSGBUS" reply --parent "$question_id" \
                --type question_answered \
                --source "telegram:callback" \
                --data "$(jq -nc --arg answer "$action" --arg job "$job" \
                    '{answer: $answer, job: $job}')" > /dev/null

            answer_callback_query "$callback_query_id" "$(echo "$action" | sed 's/.*/\u&/')d"
            edit_message_text "$chat_id" "$message_id" \
                "${original_text}

$(echo "$action" | sed 's/.*/\u&/') $(date '+%H:%M')"
            log "Processed: job=$job answer=$action question=$question_id"
            ;;
        other)
            # Mark that we're waiting for text input
            answer_callback_query "$callback_query_id" "Type your response..."
            edit_message_text "$chat_id" "$message_id" \
                "${original_text}

Waiting for text response..."
            # Store the pending "other" state so text handler knows which question
            echo "$question_id" > "$STATE_DIR/telegram-awaiting-text.tmp"
            log "Awaiting text for: job=$job question=$question_id"
            ;;
        *)
            answer_callback_query "$callback_query_id" "Unknown action: $action"
            log "WARNING: Unknown action=$action for job=$job"
            ;;
    esac
}

process_text_message() {
    local update="$1"
    local text chat_id message_id

    text=$(echo "$update" | jq -r '.message.text // ""')
    chat_id=$(echo "$update" | jq -r '.message.chat.id')

    # Only process if from our chat
    if [ "$chat_id" != "$TELEGRAM_CHAT_ID" ]; then
        return
    fi

    # Check if we're awaiting text for a question
    local awaiting_file="$STATE_DIR/telegram-awaiting-text.tmp"
    if [ ! -f "$awaiting_file" ]; then
        # Not awaiting any text reply, ignore
        return
    fi

    local question_id
    question_id=$(cat "$awaiting_file")
    rm -f "$awaiting_file"

    if [ -z "$question_id" ]; then
        return
    fi

    log "Text reply for question $question_id: $text"

    # Parse the text for action patterns
    local parsed
    parsed=$(parse_text_action "$text")
    local action_type="${parsed%% *}"
    local time_offset="${parsed#* }"

    # Look up the job from the question
    local job
    job=$("$MSGBUS" query --id "$question_id" 2>/dev/null | jq -r '.data.job // "unknown"' | head -1)

    case "$action_type" in
        remind)
            # Create a reminder event with delayed delivery
            local original_q
            original_q=$("$MSGBUS" query --id "$question_id" 2>/dev/null \
                | jq -r '.data.question // "?"' | head -1)

            "$MSGBUS" send --type reminder_due \
                --source "telegram:callback" \
                --severity question \
                --deliver-after "$time_offset" \
                --data "$(jq -nc \
                    --arg job "$job" \
                    --arg oq "$original_q" \
                    --argjson qid "$question_id" \
                    '{job: $job, original_question: $oq, original_question_id: $qid}')" > /dev/null

            log "Reminder created: question=$question_id deliver_after=$time_offset"
            ;;
        escalate)
            # Create an escalation event
            "$MSGBUS" reply --parent "$question_id" \
                --type action_created \
                --source "telegram:callback" \
                --severity critical \
                --data "$(jq -nc --arg job "$job" \
                    '{action: "escalate", job: $job}')" > /dev/null

            log "Escalated: question=$question_id to critical"
            ;;
        defer)
            # Create a reminder with longer delay
            local original_q
            original_q=$("$MSGBUS" query --id "$question_id" 2>/dev/null \
                | jq -r '.data.question // "?"' | head -1)

            "$MSGBUS" send --type reminder_due \
                --source "telegram:callback" \
                --severity question \
                --deliver-after "$time_offset" \
                --data "$(jq -nc \
                    --arg job "$job" \
                    --arg oq "$original_q" \
                    --argjson qid "$question_id" \
                    '{job: $job, original_question: $oq, original_question_id: $qid}')" > /dev/null

            log "Deferred: question=$question_id deliver_after=$time_offset"
            ;;
        custom)
            # Write as a user_response with the raw text
            "$MSGBUS" reply --parent "$question_id" \
                --type user_response \
                --source "telegram:text" \
                --data "$(jq -nc --arg answer "$text" --arg job "$job" \
                    '{answer: $answer, job: $job}')" > /dev/null

            log "Custom reply: question=$question_id text='$text'"
            ;;
    esac
}

# ============================================================================
# Polling
# ============================================================================

poll_updates() {
    local offset timeout dry_run
    offset=$(get_offset)
    timeout="${1:-0}"
    dry_run="${2:-false}"

    local url="${API_BASE}/getUpdates"
    local params
    params=$(jq -nc \
        --argjson offset "$offset" \
        --argjson timeout "$timeout" \
        '{offset: $offset, timeout: $timeout, allowed_updates: ["callback_query", "message"]}')

    local response
    response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$params" 2>/dev/null)

    local ok
    ok=$(echo "$response" | jq -r '.ok // false')
    if [ "$ok" != "true" ]; then
        log "ERROR: getUpdates failed: $(echo "$response" | jq -r '.description // "unknown"')"
        return 1
    fi

    local update_count
    update_count=$(echo "$response" | jq '.result | length')

    if [ "$update_count" -eq 0 ]; then
        return 0
    fi

    local max_update_id="$offset"

    echo "$response" | jq -c '.result[]' | while IFS= read -r update; do
        local update_id
        update_id=$(echo "$update" | jq -r '.update_id')

        # Track highest update_id
        if [ "$update_id" -ge "$max_update_id" ]; then
            max_update_id=$((update_id + 1))
            save_offset "$max_update_id"
        fi

        if [ "$dry_run" = "true" ]; then
            echo "$update" | jq .
            continue
        fi

        # Route by update type
        if echo "$update" | jq -e '.callback_query' > /dev/null 2>&1; then
            process_callback_query "$update"
        elif echo "$update" | jq -e '.message.text' > /dev/null 2>&1; then
            process_text_message "$update"
        fi
    done

    if [ "$dry_run" = "true" ]; then
        echo "Updates: $update_count"
    fi
}

# ============================================================================
# Main
# ============================================================================

DRY_RUN=false
DAEMON=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --daemon) DAEMON=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

load_env
mkdir -p "$STATE_DIR" "$LOG_DIR"

if [ "$DAEMON" = "true" ]; then
    log "Starting callback handler daemon (timeout=${POLL_TIMEOUT}s)"
    while true; do
        poll_updates "$POLL_TIMEOUT" "$DRY_RUN" || sleep 5
    done
else
    # Single poll cycle (for cron)
    poll_updates 0 "$DRY_RUN"
fi

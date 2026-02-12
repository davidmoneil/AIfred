#!/bin/bash
# msg-relay.sh - DND-aware message delivery relay for Headless Claude
#
# Polls the message bus for pending messages, checks quiet hours,
# delivers via Telegram, and marks delivered.
#
# Called after each dispatcher cycle or independently via cron.
#
# Usage:
#   msg-relay.sh              # Normal relay cycle
#   msg-relay.sh --dry-run    # Show what would be delivered
#   msg-relay.sh --test-dnd   # Show current DND state

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
REGISTRY="$JOBS_DIR/registry.yaml"
MSGBUS="$SCRIPT_DIR/msgbus.sh"
SEND_TELEGRAM="$SCRIPT_DIR/send-telegram.sh"
LOG_DIR="$JOBS_DIR/../../.claude/logs/headless"
RELAY_LOG="$LOG_DIR/relay.log"

# Colors (for terminal output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# Helpers
# ============================================================================

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$RELAY_LOG" 2>/dev/null; }

require_yq() {
    for yq_path in "yq" "$HOME/.local/bin/yq" "/usr/local/bin/yq" "/snap/bin/yq"; do
        if command -v "$yq_path" &>/dev/null 2>&1 || [ -x "$yq_path" ]; then
            echo "$yq_path"
            return 0
        fi
    done
    log "ERROR: yq is required"
    exit 1
}

# ============================================================================
# DND (Do Not Disturb) Logic
# ============================================================================

# Check if current time is within quiet hours
# Returns 0 if in quiet hours (DND active), 1 if not
is_quiet_hours() {
    local tz hour dow start_hour end_hour

    tz=$("$YQ" '.quiet_hours.timezone // "America/Denver"' "$REGISTRY" 2>/dev/null)

    # Get current hour and day-of-week in configured timezone
    hour=$(TZ="$tz" date +%H | sed 's/^0//')
    dow=$(TZ="$tz" date +%u)  # 1=Monday, 7=Sunday

    # Weekend = Saturday(6) or Sunday(7)
    if [ "$dow" -ge 6 ]; then
        start_hour=$("$YQ" '.quiet_hours.weekend.start // 23' "$REGISTRY" 2>/dev/null)
        end_hour=$("$YQ" '.quiet_hours.weekend.end // 9' "$REGISTRY" 2>/dev/null)
    else
        start_hour=$("$YQ" '.quiet_hours.weekday.start // 22' "$REGISTRY" 2>/dev/null)
        end_hour=$("$YQ" '.quiet_hours.weekday.end // 7' "$REGISTRY" 2>/dev/null)
    fi

    # Handle overnight window (e.g., 22-7 means 22,23,0,1,2,3,4,5,6)
    if [ "$start_hour" -gt "$end_hour" ]; then
        # Overnight: quiet if hour >= start OR hour < end
        if [ "$hour" -ge "$start_hour" ] || [ "$hour" -lt "$end_hour" ]; then
            return 0
        fi
    else
        # Same-day: quiet if hour >= start AND hour < end
        if [ "$hour" -ge "$start_hour" ] && [ "$hour" -lt "$end_hour" ]; then
            return 0
        fi
    fi

    return 1
}

# Check if a severity bypasses DND
severity_bypasses_dnd() {
    local severity="$1"
    local bypass_count
    bypass_count=$("$YQ" '.quiet_hours.severity_bypass | length' "$REGISTRY" 2>/dev/null || echo "0")

    for ((i=0; i<bypass_count; i++)); do
        local bypass_sev
        bypass_sev=$("$YQ" ".quiet_hours.severity_bypass[$i]" "$REGISTRY" 2>/dev/null)
        if [ "$severity" = "$bypass_sev" ]; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# Delivery
# ============================================================================

# Status emoji based on severity + event type
status_emoji() {
    local severity="$1" event_type="$2"
    case "$event_type" in
        job_failed) echo "👎" ;;
        question_asked) echo "❓" ;;
        reminder_due) echo "🔔" ;;
        *)
            case "$severity" in
                critical) echo "👎" ;;
                warning)  echo "⚠️" ;;
                info)     echo "👍" ;;
                *)        echo "📋" ;;
            esac
            ;;
    esac
}

# Format a message event for Telegram delivery
format_telegram_message() {
    local event="$1"
    local event_type severity job

    event_type=$(echo "$event" | jq -r '.event_type')
    severity=$(echo "$event" | jq -r '.severity')
    job=$(echo "$event" | jq -r '.data.job // "unknown"')

    local emoji
    emoji=$(status_emoji "$severity" "$event_type")

    case "$event_type" in
        job_completed|job_failed)
            local summary cost duration exit_code details
            summary=$(echo "$event" | jq -r '.data.summary // "No summary"')
            details=$(echo "$event" | jq -r '.data.details // empty')
            cost=$(echo "$event" | jq -r '.data.cost_usd // "?"')
            duration=$(echo "$event" | jq -r '.data.duration_secs // "?"')
            exit_code=$(echo "$event" | jq -r '.data.exit_code // 0')

            # Format duration human-readable
            local dur_fmt="${duration}s"
            if [ "$duration" != "?" ] && [ "$duration" -ge 60 ] 2>/dev/null; then
                dur_fmt="$((duration / 60))m$((duration % 60))s"
            fi

            # Build message body
            local body="${summary}"
            if [ -n "$details" ]; then
                body="${summary}
${details}"
            fi

            if [ "$event_type" = "job_failed" ]; then
                echo "${emoji} ${job} failed (exit $exit_code)
${body}
${dur_fmt} | \$${cost}"
            else
                echo "${emoji} ${job}
${body}
${dur_fmt} | \$${cost}"
            fi
            ;;
        question_asked)
            local question
            question=$(echo "$event" | jq -r '.data.question // "?"')
            echo "${emoji} ${job}
${question}"
            ;;
        reminder_due)
            local original_q
            original_q=$(echo "$event" | jq -r '.data.original_question // .data.summary // "Reminder"')
            echo "${emoji} Reminder: ${job}
${original_q}"
            ;;
        *)
            echo "${emoji} ${event_type} — ${job}"
            ;;
    esac
}

# Deliver a single event via Telegram
deliver_event() {
    local event="$1"
    local msg_id event_type severity job

    msg_id=$(echo "$event" | jq -r '.id')
    event_type=$(echo "$event" | jq -r '.event_type')
    severity=$(echo "$event" | jq -r '.severity')
    job=$(echo "$event" | jq -r '.data.job // "unknown"')

    local text
    text=$(format_telegram_message "$event")

    if [ "$event_type" = "question_asked" ]; then
        # Send as question with buttons (use send-telegram's question mode for keyboard)
        local question
        question=$(echo "$event" | jq -r '.data.question // "?"')
        local options
        options=$(echo "$event" | jq -r '.data.options // ["Approve","Deny","Skip"] | join("|")')
        if [ -x "$SEND_TELEGRAM" ]; then
            "$SEND_TELEGRAM" --question "$question" --job "$job" --options "$options" 2>/dev/null || true
        fi
    else
        # Send pre-formatted text (no --job to avoid send-telegram adding its own header)
        if [ -x "$SEND_TELEGRAM" ]; then
            "$SEND_TELEGRAM" --message "$text" --parse-mode "" 2>/dev/null || true
        fi
    fi

    # Mark delivered in the bus
    "$MSGBUS" deliver --id "$msg_id" --by relay > /dev/null
    log "Delivered: [$msg_id] $event_type ($severity) for $job"
}

# ============================================================================
# Main
# ============================================================================

DRY_RUN=false
TEST_DND=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --test-dnd) TEST_DND=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Find yq
YQ=$(require_yq)

# Ensure log directory
mkdir -p "$LOG_DIR"

# Test DND mode
if [ "$TEST_DND" = "true" ]; then
    local_tz=$("$YQ" '.quiet_hours.timezone // "America/Denver"' "$REGISTRY" 2>/dev/null)
    echo "Timezone: $local_tz"
    echo "Current time: $(TZ="$local_tz" date '+%Y-%m-%d %H:%M %Z')"
    echo "Day of week: $(TZ="$local_tz" date +%A) ($(TZ="$local_tz" date +%u))"
    if is_quiet_hours; then
        echo "DND: ACTIVE (quiet hours)"
    else
        echo "DND: INACTIVE (delivery allowed)"
    fi
    echo ""
    echo "Severity bypass:"
    "$YQ" '.quiet_hours.severity_bypass[]' "$REGISTRY" 2>/dev/null | while read -r sev; do
        echo "  - $sev"
    done
    exit 0
fi

# Get pending messages
PENDING=$("$MSGBUS" pending 2>/dev/null || true)

if [ -z "$PENDING" ]; then
    # Nothing to deliver
    exit 0
fi

DELIVERED=0
QUEUED=0
BYPASSED=0
SILENCED=0

# Check DND status once
DND_ACTIVE=false
if is_quiet_hours; then
    DND_ACTIVE=true
fi

# Process each pending message
while IFS= read -r event; do
    [ -z "$event" ] && continue

    msg_id=$(echo "$event" | jq -r '.id')
    severity=$(echo "$event" | jq -r '.severity')
    event_type=$(echo "$event" | jq -r '.event_type')
    job=$(echo "$event" | jq -r '.data.job // "unknown"')

    if [ "$DRY_RUN" = "true" ]; then
        if [ "$severity" = "info" ] && [ "$event_type" != "question_asked" ]; then
            echo "[DRY RUN] SILENT: [$msg_id] $event_type ($severity) for $job - info suppressed"
            SILENCED=$((SILENCED + 1))
        elif [ "$DND_ACTIVE" = "true" ] && ! severity_bypasses_dnd "$severity"; then
            echo "[DRY RUN] QUEUED: [$msg_id] $event_type ($severity) for $job - DND active"
            QUEUED=$((QUEUED + 1))
        else
            echo "[DRY RUN] WOULD DELIVER: [$msg_id] $event_type ($severity) for $job"
            DELIVERED=$((DELIVERED + 1))
        fi
        continue
    fi

    # Silent delivery: info severity gets recorded but not sent to Telegram
    # (questions always deliver regardless of severity)
    if [ "$severity" = "info" ] && [ "$event_type" != "question_asked" ]; then
        "$MSGBUS" deliver --id "$msg_id" --by relay-silent > /dev/null
        log "Silent: [$msg_id] $event_type ($severity) for $job"
        SILENCED=$((SILENCED + 1))
        continue
    fi

    # DND check
    if [ "$DND_ACTIVE" = "true" ]; then
        if severity_bypasses_dnd "$severity"; then
            log "DND bypass: [$msg_id] $event_type ($severity) for $job"
            deliver_event "$event"
            BYPASSED=$((BYPASSED + 1))
            DELIVERED=$((DELIVERED + 1))
        else
            # Skip - stays pending, will be picked up when DND ends
            QUEUED=$((QUEUED + 1))
        fi
    else
        deliver_event "$event"
        DELIVERED=$((DELIVERED + 1))
    fi
done <<< "$PENDING"

# Log summary
if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "DND: $([ "$DND_ACTIVE" = "true" ] && echo "ACTIVE" || echo "INACTIVE")"
    echo "Would deliver: $DELIVERED, Silent: $SILENCED, Queued: $QUEUED"
else
    if [ "$DELIVERED" -gt 0 ] || [ "$QUEUED" -gt 0 ] || [ "$SILENCED" -gt 0 ]; then
        log "Relay cycle: delivered=$DELIVERED silent=$SILENCED queued=$QUEUED bypassed=$BYPASSED dnd=$DND_ACTIVE"
    fi
fi

exit 0

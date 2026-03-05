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

# Shared utilities (colors, logging, require_yq, reg_get)
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Helpers
# ============================================================================

# Override log() to tee to relay log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$RELAY_LOG" 2>/dev/null; }

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

# Escape HTML special characters for Telegram
escape_html() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    echo "$text"
}

# Format a message event for Telegram delivery (HTML mode)
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

            # Escape HTML in dynamic content
            summary=$(escape_html "$summary")
            details=$(escape_html "$details")

            # Format duration human-readable
            local dur_fmt="${duration}s"
            if [ "$duration" != "?" ] && [ "$duration" -ge 60 ] 2>/dev/null; then
                dur_fmt="$((duration / 60))m$((duration % 60))s"
            fi

            # Header line
            local msg="${emoji} <b>${job}</b>"
            if [ "$event_type" = "job_failed" ]; then
                msg="${msg} <i>failed</i> (exit ${exit_code})"
            fi

            # Summary
            msg="${msg}
${summary}"

            # Details on separate lines (if present)
            if [ -n "$details" ]; then
                msg="${msg}

${details}"
            fi

            # Footer with metrics
            msg="${msg}

<code>${dur_fmt} · \$${cost}</code>"

            echo "$msg"
            ;;
        question_asked)
            local question
            question=$(echo "$event" | jq -r '.data.question // "?"')
            question=$(escape_html "$question")
            echo "${emoji} <b>${job}</b>
${question}"
            ;;
        reminder_due)
            local original_q
            original_q=$(echo "$event" | jq -r '.data.original_question // .data.summary // "Reminder"')
            original_q=$(escape_html "$original_q")
            echo "${emoji} <b>Reminder:</b> ${job}
${original_q}"
            ;;
        notification)
            local notif_summary
            notif_summary=$(echo "$event" | jq -r '.data.summary // "No details"')
            notif_summary=$(escape_html "$notif_summary")
            local notif_source
            notif_source=$(echo "$event" | jq -r '.source // "unknown"')
            echo "${emoji} <b>${notif_source}</b>
${notif_summary}"
            ;;
        *)
            echo "${emoji} <b>${event_type}</b> — ${job}"
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
        # Send HTML-formatted text (no --job to avoid send-telegram adding its own header)
        if [ -x "$SEND_TELEGRAM" ]; then
            "$SEND_TELEGRAM" --message "$text" --parse-mode "HTML" 2>/dev/null || true
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
DIGESTED=0

# DND state tracking for transition detection
DND_STATE_FILE="$JOBS_DIR/state/relay-dnd-state"
mkdir -p "$(dirname "$DND_STATE_FILE")"

# Check DND status once
DND_ACTIVE=false
if is_quiet_hours; then
    DND_ACTIVE=true
fi

# Detect DND transition (was active last cycle, inactive now)
DND_JUST_ENDED=false
if [ "$DND_ACTIVE" = "false" ] && [ -f "$DND_STATE_FILE" ]; then
    PREV_DND=$(cat "$DND_STATE_FILE" 2>/dev/null || echo "false")
    if [ "$PREV_DND" = "true" ]; then
        DND_JUST_ENDED=true
    fi
fi

# Save current DND state for next cycle
echo "$DND_ACTIVE" > "$DND_STATE_FILE"

# Count pending messages for digest decision
PENDING_COUNT=$(echo "$PENDING" | grep -c '^{' || true)

# ============================================================================
# DND Digest Mode
# ============================================================================
# When DND just ended and there are >3 pending messages, send a single digest
# instead of flooding Telegram with individual notifications.

deliver_digest() {
    local events="$1"

    # Separate question_asked events (need individual delivery for buttons)
    local questions=""
    local digestible=""
    local critical_count=0 warning_count=0 info_count=0
    local job_list=""

    while IFS= read -r event; do
        [ -z "$event" ] && continue
        local et sev job
        et=$(echo "$event" | jq -r '.event_type')
        sev=$(echo "$event" | jq -r '.severity')
        job=$(echo "$event" | jq -r '.data.job // "unknown"')

        if [ "$et" = "question_asked" ]; then
            questions="${questions}${event}
"
        else
            digestible="${digestible}${event}
"
            case "$sev" in
                critical) critical_count=$((critical_count + 1)) ;;
                warning)  warning_count=$((warning_count + 1)) ;;
                *)        info_count=$((info_count + 1)) ;;
            esac
            # Track unique job names
            if ! echo "$job_list" | grep -qF "$job"; then
                job_list="${job_list}${job}
"
            fi
        fi
    done <<< "$events"

    # Build digest message
    local digest_count=$((critical_count + warning_count + info_count))
    if [ "$digest_count" -gt 0 ]; then
        local digest_msg="📬 <b>${digest_count} notifications while you were away</b>
"
        if [ "$critical_count" -gt 0 ]; then
            digest_msg="${digest_msg}
👎 Critical: ${critical_count}"
        fi
        if [ "$warning_count" -gt 0 ]; then
            digest_msg="${digest_msg}
⚠️ Warning: ${warning_count}"
        fi
        if [ "$info_count" -gt 0 ]; then
            digest_msg="${digest_msg}
👍 Info: ${info_count}"
        fi

        # Add job breakdown
        digest_msg="${digest_msg}

<b>Jobs:</b>"
        while IFS= read -r jname; do
            [ -z "$jname" ] && continue
            local jcount
            jcount=$(echo "$digestible" | jq -r --arg j "$jname" 'select(.data.job == $j) | .data.job' 2>/dev/null | wc -l)
            digest_msg="${digest_msg}
• $(escape_html "$jname") (${jcount})"
        done <<< "$job_list"

        # Send the digest
        if [ -x "$SEND_TELEGRAM" ]; then
            "$SEND_TELEGRAM" --message "$digest_msg" --parse-mode "HTML" 2>/dev/null || true
        fi

        # Mark all digested events as delivered
        while IFS= read -r event; do
            [ -z "$event" ] && continue
            local mid
            mid=$(echo "$event" | jq -r '.id')
            "$MSGBUS" deliver --id "$mid" --by relay-digest > /dev/null
            DIGESTED=$((DIGESTED + 1))
        done <<< "$digestible"
        DELIVERED=$((DELIVERED + 1))  # Count digest as 1 delivery

        log "Digest sent: $digest_count messages ($critical_count critical, $warning_count warning, $info_count info)"
    fi

    # Deliver question_asked events individually (need buttons)
    while IFS= read -r event; do
        [ -z "$event" ] && continue
        deliver_event "$event"
        DELIVERED=$((DELIVERED + 1))
    done <<< "$questions"
}

# ============================================================================
# Main delivery loop
# ============================================================================

# Use digest mode if DND just ended and >3 pending messages
if [ "$DND_JUST_ENDED" = "true" ] && [ "$PENDING_COUNT" -gt 3 ] && [ "$DRY_RUN" = "false" ]; then
    log "DND ended with $PENDING_COUNT pending messages — entering digest mode"
    deliver_digest "$PENDING"
else
    # Normal per-message delivery
    while IFS= read -r event; do
        [ -z "$event" ] && continue

        msg_id=$(echo "$event" | jq -r '.id')
        severity=$(echo "$event" | jq -r '.severity')
        event_type=$(echo "$event" | jq -r '.event_type')
        job=$(echo "$event" | jq -r '.data.job // "unknown"')

        if [ "$DRY_RUN" = "true" ]; then
            if [ "$DND_ACTIVE" = "true" ] && ! severity_bypasses_dnd "$severity"; then
                echo "[DRY RUN] QUEUED: [$msg_id] $event_type ($severity) for $job - DND active"
                QUEUED=$((QUEUED + 1))
            else
                echo "[DRY RUN] WOULD DELIVER: [$msg_id] $event_type ($severity) for $job"
                DELIVERED=$((DELIVERED + 1))
            fi
            continue
        fi

        # DND check (all severities except bypass list are held during quiet hours)
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
fi

# Log summary
if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "DND: $([ "$DND_ACTIVE" = "true" ] && echo "ACTIVE" || echo "INACTIVE")"
    echo "Would deliver: $DELIVERED, Queued: $QUEUED"
else
    if [ "$DELIVERED" -gt 0 ] || [ "$QUEUED" -gt 0 ] || [ "$DIGESTED" -gt 0 ]; then
        log "Relay cycle: delivered=$DELIVERED queued=$QUEUED bypassed=$BYPASSED digested=$DIGESTED dnd=$DND_ACTIVE dnd_ended=$DND_JUST_ENDED"
    fi
fi

exit 0

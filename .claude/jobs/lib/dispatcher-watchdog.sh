#!/usr/bin/env bash
# Dispatcher Watchdog
#
# Checks if the dispatcher heartbeat file is stale (>15 minutes old).
# If stale, sends a critical Telegram alert. Runs via cron every 15 minutes.
#
# The dispatcher touches state/dispatcher-heartbeat every 5-minute cycle.
# If this file is missing or older than 15 minutes, something is wrong.

set -euo pipefail

# Auto-detect project root (two levels up from lib/)
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

SCRIPT_DIR="${PROJECT_DIR}/.claude/jobs"
HEARTBEAT_FILE="$SCRIPT_DIR/state/dispatcher-heartbeat"
ALERT_THROTTLE_FILE="$SCRIPT_DIR/state/watchdog-last-alert"
STALE_THRESHOLD_MINUTES=15
ALERT_THROTTLE_HOURS=4

# Check if heartbeat file exists
if [ ! -f "$HEARTBEAT_FILE" ]; then
    echo "[watchdog] Heartbeat file missing: $HEARTBEAT_FILE"
    STALE=true
else
    # Check age of heartbeat file
    NOW=$(date +%s)
    HEARTBEAT_AGE=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    AGE_MINUTES=$(( (NOW - HEARTBEAT_AGE) / 60 ))

    if [ "$AGE_MINUTES" -gt "$STALE_THRESHOLD_MINUTES" ]; then
        echo "[watchdog] Dispatcher heartbeat stale: ${AGE_MINUTES}m old (threshold: ${STALE_THRESHOLD_MINUTES}m)"
        STALE=true
    else
        STALE=false
    fi
fi

if [ "$STALE" = "true" ]; then
    # Throttle alerts (don't spam every 15 minutes)
    if [ -f "$ALERT_THROTTLE_FILE" ]; then
        LAST_ALERT=$(stat -c %Y "$ALERT_THROTTLE_FILE" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        HOURS_SINCE=$(( (NOW - LAST_ALERT) / 3600 ))
        if [ "$HOURS_SINCE" -lt "$ALERT_THROTTLE_HOURS" ]; then
            echo "[watchdog] Alert throttled (last sent ${HOURS_SINCE}h ago, threshold: ${ALERT_THROTTLE_HOURS}h)"
            exit 0
        fi
    fi

    # Send critical alert via message bus
    MSGBUS="$SCRIPT_DIR/lib/msgbus.sh"
    if [ -x "$MSGBUS" ]; then
        "$MSGBUS" send \
            --type notification \
            --source dispatcher-watchdog \
            --severity critical \
            --data "{\"summary\":\"Jobs dispatcher has stopped running! Heartbeat stale. Check cron and dispatcher.sh.\"}" \
            2>/dev/null || true
    fi

    # Also try direct Telegram as fallback (bus may not be relayed if dispatcher is down)
    RELAY="$SCRIPT_DIR/lib/msg-relay.sh"
    if [ -x "$RELAY" ]; then
        "$RELAY" 2>/dev/null || true
    fi

    touch "$ALERT_THROTTLE_FILE" 2>/dev/null || true
    echo "[watchdog] ALERT: Dispatcher stale, notification sent"
else
    echo "[watchdog] OK: Dispatcher heartbeat is fresh"
fi

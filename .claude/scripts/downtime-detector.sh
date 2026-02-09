#!/usr/bin/env bash
# Downtime Detector — AC-06 trigger support
# Checks if Jarvis has been idle for >30 minutes
# Usage: source or call directly
# bash 3.2 compatible (macOS)

IDLE_THRESHOLD_SECONDS=1800  # 30 minutes
ACTIVITY_FILE="/Users/aircannon/Claude/Jarvis/.claude/state/last-activity.timestamp"

detect_idle() {
    if [ ! -f "$ACTIVITY_FILE" ]; then
        echo "UNKNOWN"
        return 0
    fi

    local last_activity
    last_activity=$(cat "$ACTIVITY_FILE" 2>/dev/null)
    if [ -z "$last_activity" ]; then
        echo "UNKNOWN"
        return 0
    fi

    local now
    now=$(date +%s)
    local elapsed=$(( now - last_activity ))

    if [ "$elapsed" -gt "$IDLE_THRESHOLD_SECONDS" ]; then
        echo "IDLE"
    else
        echo "ACTIVE"
    fi
    return 0
}

# If called directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    detect_idle
fi

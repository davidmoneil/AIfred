#!/bin/bash
# weekly-digest.sh - Send weekly summary of headless job activity
#
# Queries SQLite for the past 7 days, counts successes/failures
# per job, and sends a single Telegram summary.
#
# Usage:
#   weekly-digest.sh              # Send digest for past 7 days
#   weekly-digest.sh --days 3     # Send digest for past 3 days
#   weekly-digest.sh --dry-run    # Preview without sending
#
# Cron: 0 18 * * 0  (Sunday 6 PM MST)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
JOBSDB="$SCRIPT_DIR/jobsdb.py"
SEND_TELEGRAM="$SCRIPT_DIR/send-telegram.sh"

# SQLite helper
_db() { python3 "$JOBSDB" "$@"; }

# Defaults
DAYS=7
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --days) DAYS="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Calculate cutoff timestamp
CUTOFF=$(date -u -d "$DAYS days ago" +%Y-%m-%dT%H:%M:%SZ)
NOW_LOCAL=$(TZ="America/Denver" date '+%b %-d')
START_LOCAL=$(TZ="America/Denver" date -d "$DAYS days ago" '+%b %-d')

# Query all job_completed and job_failed events in the period from SQLite
EVENTS=$(_db exec-raw \
    "SELECT json_extract(data, '$.job'), event_type, severity,
            COALESCE(json_extract(data, '$.cost_usd'), '0')
     FROM events
     WHERE (event_type = 'job_completed' OR event_type = 'job_failed')
       AND created_at >= ?
     ORDER BY id" "$CUTOFF")

if [ -z "$EVENTS" ]; then
    MSG="Weekly Digest ($START_LOCAL-$NOW_LOCAL)

No job activity in the past $DAYS days."
    if [ "$DRY_RUN" = "true" ]; then
        echo "$MSG"
        exit 0
    fi
    if [ -x "$SEND_TELEGRAM" ]; then
        "$SEND_TELEGRAM" --message "$MSG" --parse-mode "" 2>/dev/null || true
    fi
    exit 0
fi

# Count per job: total runs, successes, warnings, failures
declare -A JOB_TOTAL JOB_OK JOB_WARN JOB_FAIL
TOTAL_COST=0

while IFS=$'\t' read -r job etype severity cost; do
    [ -z "$job" ] && continue

    JOB_TOTAL[$job]=$(( ${JOB_TOTAL[$job]:-0} + 1 ))

    if [ "$etype" = "job_failed" ] || [ "$severity" = "critical" ]; then
        JOB_FAIL[$job]=$(( ${JOB_FAIL[$job]:-0} + 1 ))
    elif [ "$severity" = "warning" ]; then
        JOB_WARN[$job]=$(( ${JOB_WARN[$job]:-0} + 1 ))
    else
        JOB_OK[$job]=$(( ${JOB_OK[$job]:-0} + 1 ))
    fi

    # Accumulate cost (integer cents to avoid float issues)
    if [ "$cost" != "0" ] && [ "$cost" != "?" ] && [ "$cost" != "unknown" ] && [ -n "$cost" ]; then
        cost_cents=$(echo "$cost" | awk '{printf "%d", $1 * 100}')
        TOTAL_COST=$((TOTAL_COST + cost_cents))
    fi
done <<< "$EVENTS"

# Format cost as dollars
COST_DOLLARS=$(echo "$TOTAL_COST" | awk '{printf "%.2f", $1 / 100}')

# Build message
MSG="Weekly Digest ($START_LOCAL-$NOW_LOCAL)
"

# Sort jobs alphabetically
for job in $(echo "${!JOB_TOTAL[@]}" | tr ' ' '\n' | sort); do
    total=${JOB_TOTAL[$job]}
    ok=${JOB_OK[$job]:-0}
    warn=${JOB_WARN[$job]:-0}
    fail=${JOB_FAIL[$job]:-0}

    line="$job: $total runs"
    if [ "$fail" -eq 0 ] && [ "$warn" -eq 0 ]; then
        line="$line, all ok"
    else
        parts=""
        [ "$ok" -gt 0 ] && parts="$ok ok"
        [ "$warn" -gt 0 ] && parts="$parts $warn warn"
        [ "$fail" -gt 0 ] && parts="$parts $fail fail"
        line="$line, $parts"
    fi
    MSG="$MSG
$line"
done

MSG="$MSG

Total cost: \$$COST_DOLLARS"

if [ "$DRY_RUN" = "true" ]; then
    echo "$MSG"
    exit 0
fi

# Send via Telegram
if [ -x "$SEND_TELEGRAM" ]; then
    "$SEND_TELEGRAM" --message "$MSG" --parse-mode "" 2>/dev/null || true
    echo "Digest sent to Telegram"
else
    echo "ERROR: send-telegram.sh not found or not executable" >&2
    exit 1
fi

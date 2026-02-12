#!/bin/bash
# send-telegram.sh - Send Telegram notifications for Headless Claude
#
# Usage:
#   send-telegram.sh --message "text"
#   send-telegram.sh --message "text" --severity critical
#   send-telegram.sh --question "Restart Plex?" --job plex-troubleshoot --options "Approve|Deny|Skip"
#
# Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from .env

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$JOBS_DIR/.env"

# Load .env
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "ERROR: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in $ENV_FILE" >&2
    exit 1
fi

API_BASE="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"

# Parse arguments
MESSAGE=""
SEVERITY="info"
JOB=""
QUESTION=""
OPTIONS=""
PARSE_MODE="HTML"

while [[ $# -gt 0 ]]; do
    case $1 in
        --message|-m) MESSAGE="$2"; shift 2 ;;
        --severity|-s) SEVERITY="$2"; shift 2 ;;
        --job|-j) JOB="$2"; shift 2 ;;
        --question|-q) QUESTION="$2"; shift 2 ;;
        --options|-o) OPTIONS="$2"; shift 2 ;;
        --parse-mode) PARSE_MODE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Severity emoji mapping
severity_icon() {
    case "$1" in
        critical) echo "🔴" ;;
        warning)  echo "🟡" ;;
        info)     echo "🟢" ;;
        question) echo "❓" ;;
        *)        echo "📋" ;;
    esac
}

# Send a plain text message
send_message() {
    local text="$1"
    curl -s -X POST "${API_BASE}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc \
            --arg chat_id "$TELEGRAM_CHAT_ID" \
            --arg text "$text" \
            --arg parse_mode "$PARSE_MODE" \
            '{chat_id: $chat_id, text: $text, parse_mode: $parse_mode}')" \
        > /dev/null 2>&1
}

# Send a message with inline keyboard buttons (for approvals)
send_question() {
    local text="$1"
    local job="$2"
    local options_str="$3"

    # Build inline keyboard from pipe-separated options
    local buttons="[]"
    IFS='|' read -ra OPTS <<< "$options_str"
    for opt in "${OPTS[@]}"; do
        local callback_data="${job}:$(echo "$opt" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')"
        buttons=$(echo "$buttons" | jq --arg text "$opt" --arg data "$callback_data" \
            '. + [{"text": $text, "callback_data": $data}]')
    done

    local keyboard
    keyboard=$(jq -nc --argjson buttons "$buttons" '{"inline_keyboard": [$buttons]}')

    curl -s -X POST "${API_BASE}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc \
            --arg chat_id "$TELEGRAM_CHAT_ID" \
            --arg text "$text" \
            --arg parse_mode "$PARSE_MODE" \
            --argjson reply_markup "$keyboard" \
            '{chat_id: $chat_id, text: $text, parse_mode: $parse_mode, reply_markup: $reply_markup}')" \
        > /dev/null 2>&1
}

# Main logic
if [ -n "$QUESTION" ]; then
    # Approval/question mode
    ICON=$(severity_icon "question")
    TEXT="${ICON} <b>Approval Required</b>

<b>Job</b>: ${JOB:-unknown}
<b>Question</b>: ${QUESTION}

Tap a button to respond:"

    send_question "$TEXT" "${JOB:-unknown}" "${OPTIONS:-Approve|Deny|Skip|Other}"

elif [ -n "$MESSAGE" ]; then
    # Notification mode
    ICON=$(severity_icon "$SEVERITY")
    if [ -n "$JOB" ]; then
        TEXT="${ICON} <b>${JOB}</b>

${MESSAGE}"
    else
        TEXT="${ICON} ${MESSAGE}"
    fi

    send_message "$TEXT"
else
    echo "ERROR: Either --message or --question is required" >&2
    exit 1
fi

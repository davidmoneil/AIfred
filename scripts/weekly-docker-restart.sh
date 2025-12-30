#!/bin/bash
#
# Weekly Docker Restart Script
#
# Gracefully restarts Docker containers on a schedule to prevent
# memory leaks and ensure services stay fresh.
#
# Features:
# - Pre-restart health snapshot
# - Ordered restart of compose stacks
# - Post-restart health verification
# - Webhook notification support
# - Automatic retry for failed restarts
#
# Configuration: Copy config.sh.template to config.sh and customize.
#
# Recommended: Use systemd timer instead of cron for reliability.
# See scripts/systemd/ for timer configuration.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration if available
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi

# ============================================================================
# CONFIGURATION (override in config.sh)
# ============================================================================

# Webhook for notifications (leave empty to disable)
WEBHOOK_URL="${WEBHOOK_URL:-}"

# Notification email (for reports)
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"

# Log file
LOG_DIR="${AIFRED_DIR:-$HOME/Code/AIfred}/.claude/logs"
LOG_FILE="$LOG_DIR/docker-restart-$(date +%Y%m%d).log"

# Docker compose directories to restart (in order)
# Override in config.sh with DOCKER_COMPOSE_DIRS array
if [[ -z "${DOCKER_COMPOSE_DIRS+x}" ]]; then
    DOCKER_COMPOSE_DIRS=(
        # Add your docker-compose directories here
        # "$HOME/docker/app1"
        # "$HOME/docker/app2"
    )
fi

# Retry settings
MAX_RETRIES=3
RETRY_DELAY=30

# ============================================================================
# FUNCTIONS
# ============================================================================

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_container_health() {
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}" 2>/dev/null || echo "Docker not available"
}

restart_compose_stack() {
    local dir="$1"
    local name=$(basename "$dir")
    local attempt=1

    log "Restarting stack: $name ($dir)"

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "  Attempt $attempt of $MAX_RETRIES..."

        # Stop containers
        if docker compose -f "$dir/docker-compose.yml" down 2>&1 | tee -a "$LOG_FILE"; then
            log "  Stopped successfully"
        else
            log "  Warning: Stop had issues, continuing..."
        fi

        # Wait a moment
        sleep 5

        # Start containers
        if docker compose -f "$dir/docker-compose.yml" up -d 2>&1 | tee -a "$LOG_FILE"; then
            log "  Started successfully"

            # Wait for containers to be healthy
            sleep 15

            # Verify containers are running
            local running=$(docker compose -f "$dir/docker-compose.yml" ps --format "{{.State}}" 2>/dev/null | grep -c "running" || echo "0")
            local expected=$(docker compose -f "$dir/docker-compose.yml" config --services 2>/dev/null | wc -l || echo "0")

            if [[ $running -ge $expected ]]; then
                log "  ✓ Stack $name healthy ($running/$expected containers running)"
                return 0
            else
                log "  ⚠ Stack $name incomplete ($running/$expected containers running)"
            fi
        else
            log "  ✗ Failed to start stack $name"
        fi

        ((attempt++))
        if [[ $attempt -le $MAX_RETRIES ]]; then
            log "  Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
    done

    log "  ✗ Stack $name failed after $MAX_RETRIES attempts"
    return 1
}

send_notification() {
    local status="$1"
    local message="$2"

    # Build notification payload
    local subject="Weekly Docker Restart - $status"
    local body="$message"

    log "Sending notification: $subject"

    # Send to webhook if configured
    if [[ -n "$WEBHOOK_URL" ]]; then
        local webhook_response
        webhook_response=$(curl -sf -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
                --arg category "Weekly Restart" \
                --arg subject "$subject" \
                --arg message "$body" \
                '{category: $category, subject: $subject, message: $message}')" 2>&1) || true

        if [[ -n "$webhook_response" ]]; then
            log "  Sent to webhook"
        else
            log "  Warning: Webhook notification may have failed"
        fi
    fi

    # Could add email fallback here if msmtp is configured
    # if command -v msmtp &>/dev/null && [[ -n "$NOTIFICATION_EMAIL" ]]; then
    #     echo "$body" | msmtp "$NOTIFICATION_EMAIL"
    # fi
}

# ============================================================================
# MAIN
# ============================================================================

log "=========================================="
log "Weekly Docker Restart Starting"
log "=========================================="

# Check if we have any compose dirs configured
if [[ ${#DOCKER_COMPOSE_DIRS[@]} -eq 0 ]]; then
    log "No DOCKER_COMPOSE_DIRS configured. Edit config.sh to add directories."
    log "Exiting."
    exit 0
fi

# Pre-restart snapshot
log ""
log "Pre-restart container status:"
get_container_health >> "$LOG_FILE"

FAILED_STACKS=()
SUCCESS_STACKS=()

# Restart each stack
for dir in "${DOCKER_COMPOSE_DIRS[@]}"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/docker-compose.yml" ]]; then
        log ""
        if restart_compose_stack "$dir"; then
            SUCCESS_STACKS+=("$(basename "$dir")")
        else
            FAILED_STACKS+=("$(basename "$dir")")
        fi
    else
        log "Skipping $dir (not found or no docker-compose.yml)"
    fi
done

# Post-restart snapshot
log ""
log "Post-restart container status:"
get_container_health >> "$LOG_FILE"

# Summary
log ""
log "=========================================="
log "Weekly Docker Restart Complete"
log "=========================================="
log "Successful: ${#SUCCESS_STACKS[@]} (${SUCCESS_STACKS[*]:-none})"
log "Failed: ${#FAILED_STACKS[@]} (${FAILED_STACKS[*]:-none})"

# Send notification
if [[ ${#FAILED_STACKS[@]} -gt 0 ]]; then
    send_notification "FAILED" "Weekly restart completed with failures.

Successful: ${SUCCESS_STACKS[*]:-none}
Failed: ${FAILED_STACKS[*]}

Check logs at: $LOG_FILE"
else
    send_notification "SUCCESS" "Weekly restart completed successfully.

Restarted: ${SUCCESS_STACKS[*]:-none}

All containers healthy."
fi

log ""
log "Log saved to: $LOG_FILE"

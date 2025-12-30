#!/bin/bash
#
# Weekly Docker Restart with Health Verification
# Restarts Docker daemon and verifies all services come back up
#
# Cron: 0 3 * * 0 /home/davidmoneil/Scripts/weekly-docker-restart.sh
#
# Created: 2025-12-27

set -uo pipefail

LOG_DIR="$HOME/logs/weekly-restart"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/restart-$TIMESTAMP.log"
MAX_WAIT=120  # seconds to wait for services
CHECK_INTERVAL=10

# Webhook configuration
WEBHOOK_URL="https://n8n.theklyx.space/webhook/51ef8abf-c108-4c17-8fd1-011a76f69adf"
WEBHOOK_SECRET="ebbaafd30a9ed2631e90f8f90b68fef9e112ab622e9d039a"
NOTIFICATION_EMAIL="davidmoneil@gmail.com"

# Services to verify after restart
declare -A SERVICES=(
    ["n8n"]="http://localhost:5678/healthz"
    ["loki"]="http://localhost:3100/ready"
    ["prometheus"]="http://localhost:9090/-/healthy"
    ["neo4j"]="http://localhost:7474"
    ["postgres"]="docker:n8n_postgres:pg_isready -U postgres"
)

# Compose stacks to start (in order)
COMPOSE_STACKS=(
    "/home/davidmoneil/Docker/mydocker/n8n"
    "/home/davidmoneil/Docker/mydocker/logging"
    "/home/davidmoneil/Docker/mydocker/mcp"
    "/home/davidmoneil/Docker/mydocker/caddy"
)

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_service() {
    local name=$1
    local endpoint=$2

    if [[ "$endpoint" == docker:* ]]; then
        # Docker exec check (format: docker:container:command)
        local container=$(echo "$endpoint" | cut -d: -f2)
        local cmd=$(echo "$endpoint" | cut -d: -f3-)
        docker exec "$container" $cmd &>/dev/null
        return $?
    else
        # HTTP check
        curl -sf --connect-timeout 5 --max-time 10 "$endpoint" &>/dev/null
        return $?
    fi
}

wait_for_services() {
    local elapsed=0
    local all_up=false

    log "Waiting for services to come up (max ${MAX_WAIT}s)..."

    while [[ $elapsed -lt $MAX_WAIT ]]; do
        all_up=true
        for name in "${!SERVICES[@]}"; do
            if ! check_service "$name" "${SERVICES[$name]}"; then
                all_up=false
                break
            fi
        done

        if $all_up; then
            log "All services up after ${elapsed}s"
            return 0
        fi

        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
    done

    log "TIMEOUT: Not all services came up within ${MAX_WAIT}s"
    return 1
}

verify_services() {
    local failed=0
    local passed=0

    log "=== Service Health Check ==="

    for name in "${!SERVICES[@]}"; do
        if check_service "$name" "${SERVICES[$name]}"; then
            log "  ✓ $name: OK"
            ((passed++))
        else
            log "  ✗ $name: FAILED"
            ((failed++))
        fi
    done

    log "Results: $passed passed, $failed failed"
    return $failed
}

start_compose_stacks() {
    log "Starting Docker Compose stacks..."

    for stack_dir in "${COMPOSE_STACKS[@]}"; do
        if [[ -d "$stack_dir" ]]; then
            local stack_name=$(basename "$stack_dir")
            log "  Starting: $stack_name"
            cd "$stack_dir" && docker compose up -d 2>>"$LOG_FILE" || log "  Warning: $stack_name may have issues"
        fi
    done
}

send_notification() {
    local status=$1      # success, warning, critical
    local subject=$2     # Short subject like "Completed Successfully"
    local details=$3     # Additional details
    local containers=${4:-"unknown"}

    log "Sending notification: $status - $subject"

    # Build the full message body
    local full_message="Weekly Docker Restart Report
========================================

Status: ${status^^}
Host: $(hostname)
Time: $(date '+%Y-%m-%d %H:%M:%S %Z')

$details

----------------------------------------
Containers: $containers
Log File: $LOG_FILE
========================================
Sent by AIServer automation"

    # Send to Loki if available
    if curl -sf http://localhost:3100/ready &>/dev/null; then
        local loki_timestamp=$(date +%s)000000000
        curl -s -X POST "http://localhost:3100/loki/api/v1/push" \
            -H "Content-Type: application/json" \
            -d "{
                \"streams\": [{
                    \"stream\": {
                        \"job\": \"weekly-restart\",
                        \"host\": \"$(hostname)\",
                        \"level\": \"$status\"
                    },
                    \"values\": [[\"$loki_timestamp\", \"$subject: $details\"]]
                }]
            }" &>/dev/null
        log "  Sent to Loki"
    fi

    # Send to n8n webhook for email notification
    # Standardized format: category, subject, message
    local json_message
    json_message=$(echo "$full_message" | jq -Rs .)

    local webhook_response
    webhook_response=$(curl -sf -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
        --connect-timeout 10 \
        --max-time 30 \
        -d "{
            \"category\": \"Weekly Restart\",
            \"subject\": \"$subject\",
            \"message\": $json_message
        }" 2>&1)

    if [[ $? -eq 0 ]]; then
        log "  Sent to n8n webhook"
    else
        log "  WARNING: Failed to send to n8n webhook: $webhook_response"
        # Fallback to msmtp if available and webhook fails
        if command -v msmtp &>/dev/null && [[ -f "$HOME/.msmtprc" ]]; then
            echo -e "Subject: AIServer Message: Weekly Restart - $subject\n\n$full_message" | msmtp "$NOTIFICATION_EMAIL" 2>/dev/null
            log "  Sent via msmtp fallback"
        fi
    fi
}

main() {
    log "=========================================="
    log "Weekly Docker Restart Starting"
    log "=========================================="

    # Record pre-restart state
    local pre_containers=$(docker ps -q 2>/dev/null | wc -l)
    log "Pre-restart: $pre_containers containers running"

    # Stop Docker gracefully
    log "Stopping Docker daemon..."
    if command -v systemctl &>/dev/null; then
        sudo systemctl stop docker 2>>"$LOG_FILE"
    else
        sudo service docker stop 2>>"$LOG_FILE"
    fi

    sleep 5

    # Start Docker
    log "Starting Docker daemon..."
    if command -v systemctl &>/dev/null; then
        sudo systemctl start docker 2>>"$LOG_FILE"
    else
        sudo service docker start 2>>"$LOG_FILE"
    fi

    # Wait for Docker to be ready
    sleep 10

    if ! docker info &>/dev/null; then
        log "CRITICAL: Docker failed to start!"
        send_notification "critical" "Docker Daemon Failed" "Docker daemon is not responding after restart. Manual intervention required immediately." "0 (Docker down)"
        exit 1
    fi

    log "Docker daemon is up"

    # Start compose stacks
    start_compose_stacks

    # Wait for services
    if wait_for_services; then
        # Verify all services
        if verify_services; then
            local post_containers=$(docker ps -q 2>/dev/null | wc -l)
            log "=========================================="
            log "Weekly Restart SUCCESSFUL"
            log "Containers: $pre_containers -> $post_containers"
            log "=========================================="
            send_notification "success" "Completed Successfully" "All services restarted and passed health checks. System is fully operational." "$post_containers running"
            exit 0
        else
            local post_containers=$(docker ps -q 2>/dev/null | wc -l)
            log "=========================================="
            log "Weekly Restart PARTIAL - Some services failed"
            log "=========================================="
            send_notification "warning" "Partial Success" "Restart completed but some services failed health checks. Review the log file for details." "$post_containers running"
            exit 1
        fi
    else
        local post_containers=$(docker ps -q 2>/dev/null | wc -l)
        log "=========================================="
        log "Weekly Restart FAILED - Services did not come up"
        log "=========================================="
        send_notification "critical" "Services Failed to Start" "Services did not come up within the timeout period. Immediate attention required." "$post_containers running"
        exit 2
    fi
}

# Run main
main "$@"

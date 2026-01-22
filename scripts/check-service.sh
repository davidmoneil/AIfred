#!/bin/bash
# Script: check-service.sh
# Purpose: Health check for Docker infrastructure services
# Usage: ./check-service.sh <service-name> [options]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -uo pipefail  # Don't exit on error, we want to report status

# Configuration
AIPROJECTS_DIR="${HOME}/AIProjects"
REGISTRY_FILE="${AIPROJECTS_DIR}/.claude/context/registries/services.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") <service-name> [options]

Health check for Docker infrastructure services.

Arguments:
    service-name    Container name or partial match

Options:
    -l, --logs N    Show last N log lines (default: 20)
    -f, --full      Full inspection (include docker inspect)
    -j, --json      JSON output for automation
    -q, --quiet     Minimal output (just status)
    -h, --help      Show this help

Examples:
    $(basename "$0") n8n
    $(basename "$0") grafana --logs 50
    $(basename "$0") caddy --full
    $(basename "$0") --json prometheus

Exit Codes:
    0  Service healthy
    1  Service not found
    2  Service unhealthy/stopped
    3  Service degraded (running but errors in logs)
EOF
}

# Logging
log_info() { [[ "$QUIET" == false ]] && echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { [[ "$QUIET" == false ]] && echo -e "${GREEN}✓${NC} $1"; }
log_warning() { [[ "$QUIET" == false ]] && echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { [[ "$QUIET" == false ]] && echo -e "${RED}✗${NC} $1"; }
log_header() { [[ "$QUIET" == false ]] && echo -e "\n${CYAN}═══ $1 ═══${NC}"; }

# Parse arguments
SERVICE=""
LOG_LINES=20
FULL_INSPECT=false
JSON_OUTPUT=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -l|--logs) LOG_LINES="$2"; shift 2 ;;
        -f|--full) FULL_INSPECT=true; shift ;;
        -j|--json) JSON_OUTPUT=true; QUIET=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -*) log_error "Unknown option: $1"; show_help; exit 1 ;;
        *)
            if [[ -z "$SERVICE" ]]; then
                SERVICE="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$SERVICE" ]]; then
    log_error "Service name required"
    show_help
    exit 1
fi

# Initialize status tracking
STATUS="unknown"
ERRORS_FOUND=0
WARNINGS_FOUND=0
HEALTH_ENDPOINT=""

# Find container
log_header "Container Status: $SERVICE"

CONTAINER_INFO=$(docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -i "$SERVICE" | head -1)

if [[ -z "$CONTAINER_INFO" ]]; then
    log_error "Container not found: $SERVICE"
    if [[ "$JSON_OUTPUT" == true ]]; then
        echo '{"service":"'"$SERVICE"'","status":"not_found","healthy":false}'
    fi
    exit 1
fi

CONTAINER_NAME=$(echo "$CONTAINER_INFO" | cut -f1)
CONTAINER_STATUS=$(echo "$CONTAINER_INFO" | cut -f2)
CONTAINER_PORTS=$(echo "$CONTAINER_INFO" | cut -f3)

# Check if running
if echo "$CONTAINER_STATUS" | grep -q "Up"; then
    STATUS="running"
    UPTIME=$(echo "$CONTAINER_STATUS" | sed 's/Up //')
    log_success "Running: $CONTAINER_NAME"
    log_info "Uptime: $UPTIME"

    # Check for health status in container status
    if echo "$CONTAINER_STATUS" | grep -q "(healthy)"; then
        log_success "Health check: healthy"
    elif echo "$CONTAINER_STATUS" | grep -q "(unhealthy)"; then
        log_warning "Health check: unhealthy"
        STATUS="unhealthy"
    fi
else
    STATUS="stopped"
    log_error "Stopped: $CONTAINER_NAME"
    log_info "Status: $CONTAINER_STATUS"
fi

# Show ports if available
if [[ -n "$CONTAINER_PORTS" ]]; then
    log_info "Ports: $CONTAINER_PORTS"
fi

# Check logs for errors
log_header "Recent Logs (last $LOG_LINES lines)"

LOGS=$(docker logs --tail "$LOG_LINES" "$CONTAINER_NAME" 2>&1)

# Count errors and warnings in logs
ERRORS_FOUND=$(echo "$LOGS" | grep -ciE "error|fatal|exception|failed|critical" || echo 0)
WARNINGS_FOUND=$(echo "$LOGS" | grep -ciE "warn|warning" || echo 0)

if [[ "$QUIET" == false ]]; then
    if [[ "$ERRORS_FOUND" -gt 0 ]]; then
        log_warning "Found $ERRORS_FOUND error(s) in recent logs:"
        echo "$LOGS" | grep -iE "error|fatal|exception|failed|critical" | head -5
    fi

    if [[ "$WARNINGS_FOUND" -gt 0 ]] && [[ "$ERRORS_FOUND" -eq 0 ]]; then
        log_info "Found $WARNINGS_FOUND warning(s) in recent logs"
    fi

    if [[ "$ERRORS_FOUND" -eq 0 ]] && [[ "$WARNINGS_FOUND" -eq 0 ]]; then
        log_success "No errors or warnings in recent logs"
    fi
fi

# Update status based on logs
if [[ "$STATUS" == "running" ]] && [[ "$ERRORS_FOUND" -gt 5 ]]; then
    STATUS="degraded"
fi

# Full inspection if requested
if [[ "$FULL_INSPECT" == true ]] && [[ "$STATUS" != "stopped" ]]; then
    log_header "Container Inspection"

    # Get key info from docker inspect
    INSPECT=$(docker inspect "$CONTAINER_NAME" 2>/dev/null)

    # Image
    IMAGE=$(echo "$INSPECT" | jq -r '.[0].Config.Image')
    log_info "Image: $IMAGE"

    # Networks
    NETWORKS=$(echo "$INSPECT" | jq -r '.[0].NetworkSettings.Networks | keys[]')
    log_info "Networks: $NETWORKS"

    # Mounts
    MOUNT_COUNT=$(echo "$INSPECT" | jq '.[0].Mounts | length')
    log_info "Volume mounts: $MOUNT_COUNT"

    # Restart policy
    RESTART=$(echo "$INSPECT" | jq -r '.[0].HostConfig.RestartPolicy.Name')
    log_info "Restart policy: $RESTART"

    # Health check config
    HEALTH_CMD=$(echo "$INSPECT" | jq -r '.[0].Config.Healthcheck.Test // empty' 2>/dev/null)
    if [[ -n "$HEALTH_CMD" ]]; then
        log_info "Health check: configured"
    fi
fi

# Try health endpoint if running
if [[ "$STATUS" == "running" ]] || [[ "$STATUS" == "degraded" ]]; then
    # Extract first port mapping
    PORT=$(echo "$CONTAINER_PORTS" | grep -oE '0\.0\.0\.0:[0-9]+' | head -1 | cut -d: -f2)

    if [[ -n "$PORT" ]]; then
        # Try common health endpoints
        for ENDPOINT in "/health" "/healthz" "/api/health" "/status" "/"; do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${PORT}${ENDPOINT}" 2>/dev/null || echo "000")
            if [[ "$HTTP_CODE" =~ ^(200|204|301|302)$ ]]; then
                HEALTH_ENDPOINT="http://localhost:${PORT}${ENDPOINT}"
                [[ "$QUIET" == false ]] && log_success "HTTP endpoint responding: $HEALTH_ENDPOINT ($HTTP_CODE)"
                break
            fi
        done

        if [[ -z "$HEALTH_ENDPOINT" ]] && [[ "$QUIET" == false ]]; then
            log_info "No HTTP health endpoint found (port $PORT)"
        fi
    fi
fi

# Summary
log_header "Summary"

HEALTHY=false
EXIT_CODE=0

case "$STATUS" in
    running)
        if [[ "$ERRORS_FOUND" -eq 0 ]]; then
            log_success "Service is healthy"
            HEALTHY=true
            EXIT_CODE=0
        else
            log_warning "Service running with errors"
            EXIT_CODE=3
        fi
        ;;
    degraded)
        log_warning "Service is degraded (many errors in logs)"
        EXIT_CODE=3
        ;;
    unhealthy)
        log_error "Service is unhealthy (health check failing)"
        EXIT_CODE=2
        ;;
    stopped)
        log_error "Service is stopped"
        EXIT_CODE=2
        ;;
    *)
        log_error "Unknown status"
        EXIT_CODE=1
        ;;
esac

# JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
    cat << JSON
{
  "service": "$SERVICE",
  "container": "$CONTAINER_NAME",
  "status": "$STATUS",
  "healthy": $HEALTHY,
  "uptime": "${UPTIME:-null}",
  "errors_in_logs": $ERRORS_FOUND,
  "warnings_in_logs": $WARNINGS_FOUND,
  "health_endpoint": "${HEALTH_ENDPOINT:-null}",
  "ports": "$CONTAINER_PORTS"
}
JSON
fi

exit $EXIT_CODE

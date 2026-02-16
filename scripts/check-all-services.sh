#!/bin/bash
# Script: check-all-services.sh
# Purpose: Health check all registered Docker services
# Usage: ./check-all-services.sh [options]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -uo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SERVICE="${SCRIPT_DIR}/check-service.sh"
AIFRED_HOME="${AIFRED_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REGISTRY_FILE="${AIFRED_HOME}/.claude/context/registries/services.yaml"

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
Usage: $(basename "$0") [options]

Health check all Docker services (registered or running).

Options:
    -r, --registered    Only check registered services (from services.yaml)
    -a, --all           Check all running containers (default)
    -g, --group GROUP   Check services in specific group
    -j, --json          JSON output for automation
    -q, --quiet         Minimal output (summary only)
    -h, --help          Show this help

Examples:
    $(basename "$0")                    # Check all running containers
    $(basename "$0") --registered       # Check registered services only
    $(basename "$0") --group monitoring # Check monitoring group

Exit Codes:
    0  All services healthy
    1  Some services unhealthy
    2  Critical services down
EOF
}

# Parse arguments
MODE="all"
GROUP=""
JSON_OUTPUT=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -r|--registered) MODE="registered"; shift ;;
        -a|--all) MODE="all"; shift ;;
        -g|--group) GROUP="$2"; shift 2 ;;
        -j|--json) JSON_OUTPUT=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -*) echo "Unknown option: $1"; show_help; exit 1 ;;
        *) shift ;;
    esac
done

# Get list of services to check
get_services() {
    if [[ "$MODE" == "registered" ]] && [[ -f "$REGISTRY_FILE" ]]; then
        # Parse services.yaml for service names
        # Simple grep for now - assumes format "  service-name:"
        grep -E "^  [a-z].*:$" "$REGISTRY_FILE" 2>/dev/null | sed 's/://g' | tr -d ' ' || echo ""
    else
        # Get all running containers
        docker ps --format '{{.Names}}' 2>/dev/null
    fi
}

SERVICES=$(get_services)

if [[ -z "$SERVICES" ]]; then
    echo "No services found to check"
    exit 0
fi

# Count services
TOTAL=$(echo "$SERVICES" | wc -l)
HEALTHY=0
UNHEALTHY=0
DEGRADED=0
STOPPED=0

# Header
if [[ "$QUIET" == false ]] && [[ "$JSON_OUTPUT" == false ]]; then
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}       Service Health Check - $(date +%Y-%m-%d\ %H:%M)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
fi

# JSON array start
if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"timestamp":"'"$(date -Iseconds)"'","services":['
    FIRST=true
fi

# Check each service
while IFS= read -r SERVICE; do
    [[ -z "$SERVICE" ]] && continue

    if [[ "$JSON_OUTPUT" == true ]]; then
        # Get JSON output from check-service
        RESULT=$("$CHECK_SERVICE" "$SERVICE" --json 2>/dev/null)

        if [[ "$FIRST" == true ]]; then
            FIRST=false
        else
            echo ","
        fi
        echo "$RESULT"

        # Parse status for summary
        STATUS=$(echo "$RESULT" | jq -r '.status' 2>/dev/null)
    else
        # Run check with quiet mode
        if [[ "$QUIET" == true ]]; then
            "$CHECK_SERVICE" "$SERVICE" --quiet > /dev/null 2>&1
            EXIT_CODE=$?
        else
            echo -e "${BLUE}Checking: $SERVICE${NC}"
            "$CHECK_SERVICE" "$SERVICE" --quiet
            EXIT_CODE=$?
            echo ""
        fi

        # Map exit code to status
        case $EXIT_CODE in
            0) STATUS="running" ;;
            1) STATUS="not_found" ;;
            2) STATUS="stopped" ;;
            3) STATUS="degraded" ;;
            *) STATUS="unknown" ;;
        esac
    fi

    # Count by status
    case "$STATUS" in
        running) ((HEALTHY++)) ;;
        stopped|not_found|unhealthy) ((UNHEALTHY++)) ;;
        degraded) ((DEGRADED++)) ;;
        *) ((UNHEALTHY++)) ;;
    esac

done <<< "$SERVICES"

# JSON array end
if [[ "$JSON_OUTPUT" == true ]]; then
    echo '],'
fi

# Summary
if [[ "$JSON_OUTPUT" == true ]]; then
    cat << JSON
"summary":{
  "total":$TOTAL,
  "healthy":$HEALTHY,
  "degraded":$DEGRADED,
  "unhealthy":$UNHEALTHY,
  "timestamp":"$(date -Iseconds)"
}}
JSON
else
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "                    ${CYAN}SUMMARY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "  Total Services:  $TOTAL"
    echo -e "  ${GREEN}✓ Healthy:${NC}        $HEALTHY"
    if [[ "$DEGRADED" -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ Degraded:${NC}       $DEGRADED"
    fi
    if [[ "$UNHEALTHY" -gt 0 ]]; then
        echo -e "  ${RED}✗ Unhealthy:${NC}      $UNHEALTHY"
    fi
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

    # Overall status
    if [[ "$UNHEALTHY" -eq 0 ]] && [[ "$DEGRADED" -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All services healthy${NC}"
    elif [[ "$UNHEALTHY" -gt 0 ]]; then
        echo -e "\n${RED}✗ $UNHEALTHY service(s) need attention${NC}"
    else
        echo -e "\n${YELLOW}⚠ $DEGRADED service(s) degraded${NC}"
    fi
fi

# Exit code based on status
if [[ "$UNHEALTHY" -gt 0 ]]; then
    exit 2
elif [[ "$DEGRADED" -gt 0 ]]; then
    exit 1
else
    exit 0
fi

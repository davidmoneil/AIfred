#!/bin/bash
#
# Weekly Infrastructure Health Check
# Comprehensive validation of backups, services, credentials, and system health
#
# Usage: ./weekly-health-check.sh [--json] [--quiet] [--section SECTION]
#
# Sections: all, backup, docker, credentials, logging, network, storage, security
#
# Created: 2025-12-26
# Author: Claude Code (AI Infrastructure Project)

# Note: Not using 'set -e' to allow graceful error handling in checks
set -uo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$HOME/logs/weekly-health"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/health-report-$TIMESTAMP.txt"
JSON_FILE="$REPORT_DIR/health-report-$TIMESTAMP.json"
LOKI_URL="http://localhost:3100/loki/api/v1/push"

# Thresholds
BACKUP_MAX_AGE_HOURS=48
DISK_WARNING_PERCENT=80
DISK_CRITICAL_PERCENT=90
CERT_WARNING_DAYS=30

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Counters
CHECKS_PASSED=0
CHECKS_WARNED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0

# JSON accumulator
declare -a JSON_RESULTS=()

# Parse arguments
OUTPUT_JSON=false
QUIET_MODE=false
TARGET_SECTION="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        --json) OUTPUT_JSON=true; shift ;;
        --quiet) QUIET_MODE=true; shift ;;
        --section) TARGET_SECTION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

ensure_dirs() {
    mkdir -p "$REPORT_DIR"
}

log() {
    if [[ "$QUIET_MODE" == "false" ]]; then
        echo -e "$1" | tee -a "$REPORT_FILE"
    else
        echo -e "$1" >> "$REPORT_FILE"
    fi
}

header() {
    log ""
    log "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}${BOLD}  $1${NC}"
    log "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

subheader() {
    log ""
    log "${CYAN}── $1 ──${NC}"
}

pass() {
    log "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
    add_json_result "$2" "pass" "$1" ""
}

warn() {
    log "${YELLOW}⚠${NC} $1"
    if [[ -n "$3" ]]; then
        log "    ${YELLOW}↳ $3${NC}"
    fi
    ((CHECKS_WARNED++))
    add_json_result "$2" "warn" "$1" "$3"
}

fail() {
    log "${RED}✗${NC} $1"
    if [[ -n "$3" ]]; then
        log "    ${RED}↳ $3${NC}"
    fi
    ((CHECKS_FAILED++))
    add_json_result "$2" "fail" "$1" "$3"
}

skip() {
    log "${MAGENTA}○${NC} $1 (skipped)"
    ((CHECKS_SKIPPED++))
    add_json_result "$2" "skip" "$1" "Check skipped"
}

info() {
    log "  ${NC}$1${NC}"
}

add_json_result() {
    local check_name="$1"
    local status="$2"
    local message="$3"
    local details="${4:-}"

    JSON_RESULTS+=("{\"check\":\"$check_name\",\"status\":\"$status\",\"message\":\"$message\",\"details\":\"$details\"}")
}

send_to_loki() {
    local level=$1
    local message=$2
    local timestamp=$(date +%s)000000000

    curl -s -X POST "$LOKI_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"streams\": [{
                \"stream\": {
                    \"job\": \"weekly-health-check\",
                    \"host\": \"aiserver\",
                    \"level\": \"$level\"
                },
                \"values\": [[\"$timestamp\", \"$message\"]]
            }]
        }" > /dev/null 2>&1 || true
}

# ============================================================================
# BACKUP VALIDATION
# ============================================================================

check_backups() {
    header "BACKUP SYSTEMS"

    # --- Restic Backups ---
    subheader "Restic Backup Repository"

    export RESTIC_REPOSITORY="/mnt/backup_nas/AIServer/restic"
    export RESTIC_PASSWORD_FILE="$HOME/.restic/aiserver-backup-password.txt"

    if [[ -f "$RESTIC_PASSWORD_FILE" ]]; then
        if restic snapshots --latest 1 &>/dev/null; then
            pass "Restic repository accessible" "restic_connectivity"

            # Check last backup age - try with tag first, then without
            LAST_BACKUP=""
            RESTIC_JSON=$(restic snapshots --tag aiserver-system --latest 1 --json 2>/dev/null) || true
            if [[ -n "$RESTIC_JSON" && "$RESTIC_JSON" != "null" && "$RESTIC_JSON" != "[]" ]]; then
                LAST_BACKUP=$(echo "$RESTIC_JSON" | jq -r '.[0].time // empty' 2>/dev/null) || true
            fi

            # If no tagged backups, check any backups
            if [[ -z "$LAST_BACKUP" ]]; then
                RESTIC_JSON=$(restic snapshots --latest 1 --json 2>/dev/null) || true
                if [[ -n "$RESTIC_JSON" && "$RESTIC_JSON" != "null" && "$RESTIC_JSON" != "[]" ]]; then
                    LAST_BACKUP=$(echo "$RESTIC_JSON" | jq -r '.[0].time // empty' 2>/dev/null) || true
                fi
            fi

            if [[ -n "$LAST_BACKUP" ]]; then
                LAST_BACKUP_EPOCH=$(date -d "$LAST_BACKUP" +%s 2>/dev/null) || LAST_BACKUP_EPOCH=0
                NOW_EPOCH=$(date +%s)
                if [[ $LAST_BACKUP_EPOCH -gt 0 ]]; then
                    AGE_HOURS=$(( (NOW_EPOCH - LAST_BACKUP_EPOCH) / 3600 ))
                    info "Last backup: $LAST_BACKUP ($AGE_HOURS hours ago)"

                    if [[ $AGE_HOURS -gt $BACKUP_MAX_AGE_HOURS ]]; then
                        fail "Restic backup is stale ($AGE_HOURS hours old)" "restic_age" "Exceeds ${BACKUP_MAX_AGE_HOURS}h threshold"
                    else
                        pass "Restic backup is recent ($AGE_HOURS hours)" "restic_age"
                    fi
                else
                    info "Last backup: $LAST_BACKUP (could not parse date)"
                    pass "Restic backup exists" "restic_age"
                fi

                # Check snapshot count
                SNAPSHOT_COUNT=$(restic snapshots --json 2>/dev/null | jq 'length' 2>/dev/null) || SNAPSHOT_COUNT="unknown"
                info "Total snapshots: $SNAPSHOT_COUNT"

                # Get repo stats
                REPO_SIZE=$(du -sh "$RESTIC_REPOSITORY" 2>/dev/null | cut -f1) || REPO_SIZE="unknown"
                info "Repository size: $REPO_SIZE"
            else
                warn "No Restic snapshots found" "restic_snapshots" "Repository exists but empty"
            fi
        else
            fail "Cannot access Restic repository" "restic_connectivity" "Check mount and credentials"
        fi
    else
        skip "Restic password file not found" "restic_connectivity"
    fi

    # Check systemd timer
    if systemctl is-active --quiet restic-backup.timer 2>/dev/null; then
        pass "Restic backup timer is active" "restic_timer"
        # Get next run time from systemctl status (more reliable)
        NEXT_RUN_LINE=$(systemctl status restic-backup.timer 2>/dev/null | grep "Trigger:" | head -1) || true
        if [[ -n "$NEXT_RUN_LINE" ]]; then
            NEXT_RUN_FMT=$(echo "$NEXT_RUN_LINE" | sed 's/.*Trigger: //' | cut -d';' -f1)
            info "Next scheduled: $NEXT_RUN_FMT"
        fi
    else
        warn "Restic backup timer is inactive" "restic_timer" "Timer not running"
    fi

    # --- Service-Specific Backups ---
    subheader "Service Backups"

    # n8n PostgreSQL backup
    N8N_BACKUP_DIR="/mydocker/n8n/backups/postgres"
    if [[ -d "$N8N_BACKUP_DIR" ]]; then
        LATEST_N8N=$(find "$N8N_BACKUP_DIR" -name "*.sql.gz" -type f -mtime -2 2>/dev/null | head -1)
        if [[ -n "$LATEST_N8N" ]]; then
            BACKUP_DATE=$(stat -c %y "$LATEST_N8N" | cut -d' ' -f1)
            pass "n8n PostgreSQL backup exists ($BACKUP_DATE)" "n8n_postgres_backup"
        else
            warn "n8n PostgreSQL backup is stale (>48h)" "n8n_postgres_backup" "No recent backup found"
        fi
    else
        skip "n8n backup directory not found" "n8n_postgres_backup"
    fi

    # MISP backup
    MISP_BACKUP_DIR="/mydocker/misp/backups"
    if [[ -d "$MISP_BACKUP_DIR" ]]; then
        LATEST_MISP=$(find "$MISP_BACKUP_DIR" -type f -mtime -2 2>/dev/null | head -1)
        if [[ -n "$LATEST_MISP" ]]; then
            pass "MISP backup exists (recent)" "misp_backup"
        else
            warn "MISP backup is stale (>48h)" "misp_backup" "No recent backup found"
        fi
    else
        skip "MISP backup directory not found" "misp_backup"
    fi

    # OpenWebUI backup
    OPENWEBUI_BACKUP_DIR="/mydocker/backups/openwebui"
    if [[ -d "$OPENWEBUI_BACKUP_DIR" ]]; then
        LATEST_OWU=$(find "$OPENWEBUI_BACKUP_DIR" -type f -mtime -3 2>/dev/null | head -1)
        if [[ -n "$LATEST_OWU" ]]; then
            pass "OpenWebUI backup exists (recent)" "openwebui_backup"
        else
            warn "OpenWebUI backup is stale" "openwebui_backup" "No recent backup found"
        fi
    else
        skip "OpenWebUI backup directory not found" "openwebui_backup"
    fi
}

# ============================================================================
# DOCKER CONTAINER HEALTH
# ============================================================================

check_docker() {
    header "DOCKER SERVICES"

    # Check Docker daemon
    subheader "Docker Daemon"
    if docker info &>/dev/null; then
        pass "Docker daemon is running" "docker_daemon"

        DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
        info "Docker version: $DOCKER_VERSION"
    else
        fail "Docker daemon is not running" "docker_daemon" "Cannot communicate with Docker"
        return
    fi

    # Container health summary
    subheader "Container Status"

    TOTAL_CONTAINERS=$(docker ps -a --format '{{.Names}}' | wc -l)
    RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)
    UNHEALTHY_CONTAINERS=$(docker ps --filter "health=unhealthy" --format '{{.Names}}' 2>/dev/null | wc -l)
    RESTARTING_CONTAINERS=$(docker ps --filter "status=restarting" --format '{{.Names}}' | wc -l)

    info "Total containers: $TOTAL_CONTAINERS"
    info "Running: $RUNNING_CONTAINERS"

    if [[ $RUNNING_CONTAINERS -eq 0 ]]; then
        fail "No containers running" "docker_running" "All containers stopped"
    elif [[ $RUNNING_CONTAINERS -lt 15 ]]; then
        warn "Fewer containers than expected ($RUNNING_CONTAINERS/~18)" "docker_running" "Some containers may be down"
    else
        pass "$RUNNING_CONTAINERS containers running" "docker_running"
    fi

    if [[ $UNHEALTHY_CONTAINERS -gt 0 ]]; then
        UNHEALTHY_LIST=$(docker ps --filter "health=unhealthy" --format '{{.Names}}' | tr '\n' ', ')
        fail "$UNHEALTHY_CONTAINERS unhealthy containers: $UNHEALTHY_LIST" "docker_health" "Containers need attention"
    else
        pass "No unhealthy containers" "docker_health"
    fi

    if [[ $RESTARTING_CONTAINERS -gt 0 ]]; then
        RESTARTING_LIST=$(docker ps --filter "status=restarting" --format '{{.Names}}' | tr '\n' ', ')
        fail "$RESTARTING_CONTAINERS containers in restart loop: $RESTARTING_LIST" "docker_restart_loop" "Check container logs"
    else
        pass "No containers in restart loop" "docker_restart_loop"
    fi

    # Critical services check
    subheader "Critical Services"

    declare -a CRITICAL_SERVICES=("caddy" "n8n" "n8n-postgres" "loki" "grafana" "promtail")

    for service in "${CRITICAL_SERVICES[@]}"; do
        if docker ps --format '{{.Names}}' | grep -qE "^${service}$|_${service}_|${service}_|${service}-"; then
            CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "^${service}$|_${service}_|${service}_|${service}-" | head -1)
            UPTIME=$(docker ps --format '{{.Status}}' --filter "name=$CONTAINER_NAME" | head -1)
            # Check container health if available
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null) || HEALTH="none"
            if [[ "$HEALTH" == "unhealthy" ]]; then
                HEALTH_LOG=$(docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' "$CONTAINER_NAME" 2>/dev/null | tail -c 100)
                warn "$service: running but UNHEALTHY" "docker_$service" "Health check failing: ${HEALTH_LOG:0:80}"
            else
                pass "$service: running ($UPTIME)" "docker_$service"
            fi
        else
            # Check if container exists but is stopped
            STOPPED_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -E "^${service}$|_${service}_|${service}_|${service}-" | head -1)
            if [[ -n "$STOPPED_CONTAINER" ]]; then
                # Get exit code and last log lines
                EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' "$STOPPED_CONTAINER" 2>/dev/null) || EXIT_CODE="unknown"
                STOPPED_AT=$(docker inspect --format='{{.State.FinishedAt}}' "$STOPPED_CONTAINER" 2>/dev/null) || STOPPED_AT="unknown"
                LAST_LOG=$(docker logs --tail 3 "$STOPPED_CONTAINER" 2>&1 | tail -c 100 | tr '\n' ' ')

                if [[ "$EXIT_CODE" == "0" ]]; then
                    fail "$service: STOPPED (exit 0)" "docker_$service" "Container exited cleanly at ${STOPPED_AT:0:19} - may need restart"
                elif [[ "$EXIT_CODE" == "137" ]]; then
                    fail "$service: KILLED (exit 137/OOM)" "docker_$service" "Container was killed (OOM or manual) at ${STOPPED_AT:0:19}"
                elif [[ "$EXIT_CODE" == "1" ]]; then
                    fail "$service: CRASHED (exit 1)" "docker_$service" "Container crashed: ${LAST_LOG:0:60}"
                else
                    fail "$service: STOPPED (exit $EXIT_CODE)" "docker_$service" "Container stopped at ${STOPPED_AT:0:19}: ${LAST_LOG:0:60}"
                fi
            else
                fail "$service: NOT FOUND" "docker_$service" "No container matching '$service' exists - check compose file"
            fi
        fi
    done

    # Check for high restart counts
    subheader "Container Stability"

    HIGH_RESTART=$(docker ps --format '{{.Names}} {{.Status}}' | grep -E 'Restarting|restart' || true)
    if [[ -n "$HIGH_RESTART" ]]; then
        warn "Containers with restart issues detected" "docker_stability" "$HIGH_RESTART"
    else
        pass "All containers stable (no restart issues)" "docker_stability"
    fi

    # Watchtower status
    subheader "Auto-Update (Watchtower)"

    if docker ps --format '{{.Names}}' | grep -q watchtower; then
        pass "Watchtower is running" "watchtower"
    else
        warn "Watchtower is not running" "watchtower" "Auto-updates disabled"
    fi
}

# ============================================================================
# CREDENTIAL & API VALIDATION
# ============================================================================

# Helper function to check HTTP endpoint with detailed error reporting
check_http_endpoint() {
    local url="$1"
    local name="$2"
    local check_id="$3"
    local severity="${4:-fail}"  # fail or warn
    local timeout="${5:-10}"

    local response
    local http_code
    local curl_exit

    response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" --connect-timeout "$timeout" --max-time "$timeout" "$url" 2>&1)
    curl_exit=$?

    if [[ $curl_exit -eq 0 ]]; then
        http_code=$(echo "$response" | cut -d'|' -f1)
        response_time=$(echo "$response" | cut -d'|' -f2)

        if [[ "$http_code" =~ ^(200|201|204|301|302|303|307|308|401|403)$ ]]; then
            pass "$name responding (HTTP $http_code, ${response_time}s)" "$check_id"
            return 0
        else
            if [[ "$severity" == "fail" ]]; then
                fail "$name returned HTTP $http_code" "$check_id" "Unexpected status code"
            else
                warn "$name returned HTTP $http_code" "$check_id" "Unexpected status code"
            fi
            return 1
        fi
    else
        # Parse curl exit code for specific error
        case $curl_exit in
            6)  detail="Could not resolve host" ;;
            7)  detail="Connection refused - service not running or port blocked" ;;
            22) detail="HTTP error returned" ;;
            28) detail="Connection timed out after ${timeout}s" ;;
            35) detail="SSL/TLS handshake failed" ;;
            52) detail="Empty response from server" ;;
            56) detail="Network receive error" ;;
            *)  detail="curl error code $curl_exit" ;;
        esac

        if [[ "$severity" == "fail" ]]; then
            fail "$name not responding" "$check_id" "$detail"
        else
            warn "$name not responding" "$check_id" "$detail"
        fi
        return 1
    fi
}

check_credentials() {
    header "CREDENTIALS & API VALIDATION"

    # --- API Endpoints ---
    subheader "API Health Checks"

    # n8n API
    check_http_endpoint "http://localhost:5678/healthz" "n8n API" "api_n8n" "fail"

    # Grafana API
    if curl -sf "http://localhost:3000/api/health" --connect-timeout 10 &>/dev/null; then
        GRAFANA_RESP=$(curl -s "http://localhost:3000/api/health" --connect-timeout 5 2>/dev/null)
        GRAFANA_DB=$(echo "$GRAFANA_RESP" | jq -r '.database // "unknown"' 2>/dev/null) || GRAFANA_DB="unknown"
        GRAFANA_VER=$(echo "$GRAFANA_RESP" | jq -r '.version // "unknown"' 2>/dev/null) || GRAFANA_VER="unknown"
        pass "Grafana API responding (db: $GRAFANA_DB, v$GRAFANA_VER)" "api_grafana"
    else
        check_http_endpoint "http://localhost:3000/api/health" "Grafana API" "api_grafana" "fail"
    fi

    # Loki API
    LOKI_RESP=$(curl -s "http://localhost:3100/ready" --connect-timeout 10 2>&1)
    LOKI_EXIT=$?
    if [[ $LOKI_EXIT -eq 0 ]] && echo "$LOKI_RESP" | grep -qi "ready"; then
        pass "Loki API responding (ready)" "api_loki"
    else
        check_http_endpoint "http://localhost:3100/ready" "Loki API" "api_loki" "fail"
    fi

    # Prometheus API
    check_http_endpoint "http://localhost:9090/-/healthy" "Prometheus API" "api_prometheus" "warn"

    # MISP API
    # MISP removed - not deployed

    # OpenWebUI
    check_http_endpoint "http://localhost:3001" "OpenWebUI" "api_openwebui" "warn"

    # MCP Gateway - runs as native process on port 8080 (not Docker container)
    # Redirects to /sse, so check root endpoint
    check_http_endpoint "http://localhost:8080" "MCP Gateway" "api_mcp_gateway" "warn" 5

    # --- Database Connectivity ---
    subheader "Database Connectivity"

    # PostgreSQL (n8n) - try multiple container names
    PG_CONTAINERS=("n8n_postgres" "n8n-postgres" "n8n-n8n-postgres-1" "postgres")
    PG_FOUND=false
    PG_ERROR=""

    for container in "${PG_CONTAINERS[@]}"; do
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            PG_RESULT=$(docker exec "$container" pg_isready -U postgres 2>&1)
            PG_EXIT=$?
            if [[ $PG_EXIT -eq 0 ]]; then
                pass "PostgreSQL ($container) accepting connections" "db_postgres_n8n"
                PG_FOUND=true
                break
            else
                PG_ERROR="Container $container exists but pg_isready failed: ${PG_RESULT:0:80}"
            fi
        fi
    done

    if [[ "$PG_FOUND" == "false" ]]; then
        if [[ -n "$PG_ERROR" ]]; then
            fail "PostgreSQL not responding" "db_postgres_n8n" "$PG_ERROR"
        else
            # Check if any postgres container exists but is stopped
            STOPPED_PG=$(docker ps -a --filter "name=postgres" --filter "status=exited" --format '{{.Names}}' | head -1)
            if [[ -n "$STOPPED_PG" ]]; then
                fail "PostgreSQL not responding" "db_postgres_n8n" "Container '$STOPPED_PG' exists but is stopped"
            else
                fail "PostgreSQL not responding" "db_postgres_n8n" "No postgres container found running"
            fi
        fi
    fi

    # Neo4j
    check_http_endpoint "http://localhost:7474" "Neo4j browser" "db_neo4j" "warn"

    # --- External Service Tests ---
    subheader "External Service Connectivity"

    # Test internet connectivity
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        pass "Internet connectivity OK" "net_internet"
    else
        fail "Internet connectivity FAILED" "net_internet" "Cannot reach external networks"
    fi

    # Test DNS resolution
    if host google.com &>/dev/null; then
        pass "DNS resolution working" "net_dns"
    else
        fail "DNS resolution FAILED" "net_dns" "Cannot resolve domain names"
    fi
}

# ============================================================================
# LOGGING STACK HEALTH
# ============================================================================

check_logging() {
    header "LOGGING & MONITORING STACK"

    subheader "Loki Log Ingestion"

    # Check if Loki is receiving logs
    if curl -s "http://localhost:3100/ready" | grep -q "ready"; then
        pass "Loki is ready" "loki_ready"

        # Query recent log volume
        RECENT_LOGS=$(curl -s "http://localhost:3100/loki/api/v1/query?query=count_over_time({job=~\".%2B\"}[1h])" 2>/dev/null | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null || echo "0")

        if [[ "$RECENT_LOGS" -gt 0 ]]; then
            pass "Loki receiving logs ($RECENT_LOGS entries/hour)" "loki_ingestion"
        else
            warn "Loki may not be receiving logs" "loki_ingestion" "No recent log entries"
        fi
    else
        fail "Loki is not ready" "loki_ready" "Check Loki container"
    fi

    subheader "Promtail Status"

    if curl -sf "http://localhost:9080/ready" &>/dev/null; then
        pass "Promtail is ready" "promtail_ready"

        # Check targets
        TARGETS=$(curl -s "http://localhost:9080/targets" 2>/dev/null | grep -c "state.*active" || echo "0")
        info "Active scrape targets: $TARGETS"
    else
        fail "Promtail is not ready" "promtail_ready" "Check Promtail container"
    fi

    subheader "Grafana Dashboards"

    if curl -sf "http://localhost:3000/api/health" &>/dev/null; then
        pass "Grafana is healthy" "grafana_health"

        # Check datasources
        DATASOURCES=$(curl -s "http://localhost:3000/api/datasources" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
        info "Configured datasources: $DATASOURCES"
    else
        fail "Grafana health check failed" "grafana_health" "Check Grafana container"
    fi

    subheader "Audit Log System"

    AUDIT_LOG="$HOME/AIProjects/.claude/logs/audit.jsonl"
    if [[ -f "$AUDIT_LOG" ]]; then
        AUDIT_SIZE=$(du -h "$AUDIT_LOG" | cut -f1)
        AUDIT_LINES=$(wc -l < "$AUDIT_LOG")
        LAST_AUDIT=$(tail -1 "$AUDIT_LOG" 2>/dev/null | jq -r '.timestamp // "unknown"' 2>/dev/null || echo "unknown")

        pass "Audit log exists ($AUDIT_SIZE, $AUDIT_LINES entries)" "audit_log"
        info "Last entry: $LAST_AUDIT"
    else
        warn "Audit log file not found" "audit_log" "Claude Code audit logging may not be configured"
    fi
}

# ============================================================================
# NETWORK & SSH CONNECTIVITY
# ============================================================================

check_network() {
    header "NETWORK & SSH CONNECTIVITY"

    subheader "Infrastructure Hosts"

    declare -A HOSTS=(
        ["AIServer"]="192.168.1.196"
        ["MediaServer"]="192.168.1.179"
        ["NAS-Primary"]="192.168.1.96"
        ["NAS-Backup"]="192.168.1.100"
        ["UDM-Pro"]="192.168.1.1"
    )

    for host in "${!HOSTS[@]}"; do
        ip="${HOSTS[$host]}"
        if ping -c 1 -W 3 "$ip" &>/dev/null; then
            pass "$host ($ip) is reachable" "ping_${host,,}"
        else
            fail "$host ($ip) is unreachable" "ping_${host,,}" "Host not responding to ping"
        fi
    done

    subheader "SSH Connectivity"

    # MediaServer SSH
    SSH_ERR=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new MediaServer "echo OK" 2>&1)
    SSH_EXIT=$?
    if [[ $SSH_EXIT -eq 0 ]]; then
        pass "SSH to MediaServer working" "ssh_mediaserver"
    else
        # Parse specific SSH error
        if echo "$SSH_ERR" | grep -qi "connection refused"; then
            SSH_DETAIL="Connection refused - SSH server not running or port blocked"
        elif echo "$SSH_ERR" | grep -qi "connection timed out\|timed out"; then
            SSH_DETAIL="Connection timed out - host unreachable or firewall blocking"
        elif echo "$SSH_ERR" | grep -qi "no route to host"; then
            SSH_DETAIL="No route to host - network unreachable"
        elif echo "$SSH_ERR" | grep -qi "permission denied"; then
            SSH_DETAIL="Permission denied - key not authorized or wrong user"
        elif echo "$SSH_ERR" | grep -qi "host key verification failed"; then
            SSH_DETAIL="Host key verification failed - key changed or not in known_hosts"
        elif echo "$SSH_ERR" | grep -qi "could not resolve"; then
            SSH_DETAIL="Could not resolve hostname - check ~/.ssh/config or DNS"
        else
            SSH_DETAIL="Error: ${SSH_ERR:0:100}"
        fi
        warn "SSH to MediaServer failed" "ssh_mediaserver" "$SSH_DETAIL"
    fi

    # UDM Pro SSH (if configured)
    SSH_ERR=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new udm-pro "echo OK" 2>&1)
    SSH_EXIT=$?
    if [[ $SSH_EXIT -eq 0 ]]; then
        pass "SSH to UDM Pro working" "ssh_udmpro"
    else
        if echo "$SSH_ERR" | grep -qi "connection refused"; then
            SSH_DETAIL="Connection refused - SSH not enabled on UDM"
        elif echo "$SSH_ERR" | grep -qi "connection timed out\|timed out"; then
            SSH_DETAIL="Connection timed out - host unreachable"
        elif echo "$SSH_ERR" | grep -qi "permission denied"; then
            SSH_DETAIL="Permission denied - key not authorized"
        elif echo "$SSH_ERR" | grep -qi "could not resolve"; then
            SSH_DETAIL="Could not resolve hostname - add to ~/.ssh/config"
        else
            SSH_DETAIL="Error: ${SSH_ERR:0:100}"
        fi
        warn "SSH to UDM Pro not available" "ssh_udmpro" "$SSH_DETAIL"
    fi

    subheader "NFS Mounts"

    # Check Synology NAS mount (may be subdirectory mounts like /mnt/synology_nas/Media)
    NAS_MOUNT_COUNT=$(mount | grep -c "synology_nas" 2>/dev/null || echo "0")
    if [[ $NAS_MOUNT_COUNT -gt 0 ]]; then
        # Test if mounts are actually responsive (not stale)
        if timeout 5 ls /mnt/synology_nas >/dev/null 2>&1; then
            # Get free space from any mounted share
            NAS_FREE=$(df -h /mnt/synology_nas/Media 2>/dev/null | tail -1 | awk '{print $4}') || NAS_FREE="unknown"
            pass "Synology NAS mounted ($NAS_MOUNT_COUNT shares, $NAS_FREE free)" "nfs_synology"
        else
            fail "Synology NAS mount is STALE" "nfs_synology" "Mounts exist but not responding - NAS may be down or network issue"
        fi
    else
        # Check why not mounted
        if [[ ! -d /mnt/synology_nas ]]; then
            MOUNT_DETAIL="Mount point /mnt/synology_nas does not exist"
        elif grep -q "synology_nas" /etc/fstab 2>/dev/null; then
            # Check if NAS is reachable - extract first IP/hostname from fstab entry
            NAS_IP=$(grep "synology_nas" /etc/fstab 2>/dev/null | head -1 | awk '{print $1}' | cut -d: -f1 | head -1)
            if [[ -n "$NAS_IP" ]] && ! ping -c 1 -W 2 "$NAS_IP" &>/dev/null; then
                MOUNT_DETAIL="NAS ($NAS_IP) unreachable - check network or NAS power"
            else
                MOUNT_DETAIL="In fstab but not mounted - try: sudo mount -a"
            fi
        else
            MOUNT_DETAIL="Not configured in /etc/fstab"
        fi
        fail "Synology NAS not mounted" "nfs_synology" "$MOUNT_DETAIL"
    fi

    # Check Backup NAS mount
    if mountpoint -q /mnt/backup_nas 2>/dev/null; then
        if timeout 5 ls /mnt/backup_nas >/dev/null 2>&1; then
            BACKUP_FREE=$(df -h /mnt/backup_nas 2>/dev/null | tail -1 | awk '{print $4}')
            pass "Backup NAS mounted (/mnt/backup_nas, $BACKUP_FREE free)" "nfs_backup"
        else
            fail "Backup NAS mount is STALE" "nfs_backup" "Mount exists but not responding"
        fi
    else
        if [[ ! -d /mnt/backup_nas ]]; then
            MOUNT_DETAIL="Mount point /mnt/backup_nas does not exist"
        elif grep -q "backup_nas" /etc/fstab 2>/dev/null; then
            MOUNT_DETAIL="In fstab but not mounted - try: sudo mount /mnt/backup_nas"
        else
            MOUNT_DETAIL="Not configured in /etc/fstab"
        fi
        warn "Backup NAS not mounted" "nfs_backup" "$MOUNT_DETAIL"
    fi

    subheader "Caddy Reverse Proxy"

    # Check Caddy admin API
    CADDY_RESP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:2019/config/" 2>&1)
    CADDY_EXIT=$?
    if [[ $CADDY_EXIT -eq 0 ]] && [[ "$CADDY_RESP" =~ ^2 ]]; then
        pass "Caddy admin API responding (HTTP $CADDY_RESP)" "caddy_admin"
    else
        if [[ $CADDY_EXIT -eq 7 ]]; then
            warn "Caddy admin API not responding" "caddy_admin" "Connection refused on port 2019 - admin API may be disabled in Caddyfile"
        elif [[ $CADDY_EXIT -eq 28 ]]; then
            warn "Caddy admin API not responding" "caddy_admin" "Connection timed out on port 2019"
        else
            warn "Caddy admin API not responding" "caddy_admin" "HTTP $CADDY_RESP (curl exit $CADDY_EXIT)"
        fi
    fi

    # Test a public endpoint with detailed error
    PUBLIC_URL="https://n8n.theklyx.space"
    PUBLIC_RESP=$(curl -s -o /dev/null -w "%{http_code}|%{ssl_verify_result}" --connect-timeout 10 --max-time 15 "$PUBLIC_URL" 2>&1)
    PUBLIC_EXIT=$?
    HTTP_CODE=$(echo "$PUBLIC_RESP" | cut -d'|' -f1)
    SSL_RESULT=$(echo "$PUBLIC_RESP" | cut -d'|' -f2)

    if [[ $PUBLIC_EXIT -eq 0 ]] && [[ "$HTTP_CODE" =~ ^(200|301|302|401|403)$ ]]; then
        pass "Public endpoints accessible (n8n.theklyx.space HTTP $HTTP_CODE)" "caddy_public"
    else
        if [[ $PUBLIC_EXIT -eq 6 ]]; then
            fail "Public endpoint failed" "caddy_public" "DNS resolution failed for n8n.theklyx.space"
        elif [[ $PUBLIC_EXIT -eq 7 ]]; then
            fail "Public endpoint failed" "caddy_public" "Connection refused - Caddy not listening on 443 or port blocked"
        elif [[ $PUBLIC_EXIT -eq 28 ]]; then
            fail "Public endpoint failed" "caddy_public" "Connection timed out - firewall or routing issue"
        elif [[ $PUBLIC_EXIT -eq 35 ]] || [[ "$SSL_RESULT" != "0" ]]; then
            fail "Public endpoint failed" "caddy_public" "SSL/TLS error (verify result: $SSL_RESULT) - certificate issue"
        elif [[ "$HTTP_CODE" == "502" ]]; then
            warn "Public endpoint degraded" "caddy_public" "HTTP 502 Bad Gateway - upstream service (n8n) may be down"
        elif [[ "$HTTP_CODE" == "503" ]]; then
            warn "Public endpoint degraded" "caddy_public" "HTTP 503 Service Unavailable"
        elif [[ "$HTTP_CODE" == "504" ]]; then
            warn "Public endpoint degraded" "caddy_public" "HTTP 504 Gateway Timeout - upstream not responding"
        else
            warn "Public endpoint issue" "caddy_public" "HTTP $HTTP_CODE (curl exit $PUBLIC_EXIT)"
        fi
    fi
}

# ============================================================================
# STORAGE & CERTIFICATES
# ============================================================================

check_storage() {
    header "STORAGE & CERTIFICATES"

    subheader "Disk Usage"

    # Check key filesystems
    declare -A FILESYSTEMS=(
        ["/"]="root"
        ["/home"]="home"
        ["/mydocker"]="docker_data"
    )

    for mount in "${!FILESYSTEMS[@]}"; do
        name="${FILESYSTEMS[$mount]}"
        if df "$mount" &>/dev/null; then
            USAGE=$(df "$mount" | tail -1 | awk '{print $5}' | tr -d '%')
            AVAIL=$(df -h "$mount" | tail -1 | awk '{print $4}')

            if [[ $USAGE -ge $DISK_CRITICAL_PERCENT ]]; then
                fail "$mount at ${USAGE}% (CRITICAL, $AVAIL free)" "disk_$name" "Disk nearly full"
            elif [[ $USAGE -ge $DISK_WARNING_PERCENT ]]; then
                warn "$mount at ${USAGE}% ($AVAIL free)" "disk_$name" "Disk usage elevated"
            else
                pass "$mount at ${USAGE}% ($AVAIL free)" "disk_$name"
            fi
        fi
    done

    # Docker disk usage
    subheader "Docker Storage"

    DOCKER_USAGE=$(docker system df --format '{{.Type}}: {{.Size}}' 2>/dev/null | tr '\n' ', ')
    info "Docker usage: $DOCKER_USAGE"

    # Check for dangling images/volumes
    DANGLING_IMAGES=$(docker images -f "dangling=true" -q | wc -l)
    DANGLING_VOLUMES=$(docker volume ls -f "dangling=true" -q | wc -l)

    if [[ $DANGLING_IMAGES -gt 10 ]] || [[ $DANGLING_VOLUMES -gt 5 ]]; then
        warn "Docker cleanup recommended ($DANGLING_IMAGES dangling images, $DANGLING_VOLUMES dangling volumes)" "docker_cleanup" "Run docker system prune"
    else
        pass "Docker storage clean ($DANGLING_IMAGES dangling images)" "docker_cleanup"
    fi

    subheader "Certificate Status"

    # Check Let's Encrypt certificates via Caddy
    CADDY_CERTS_DIR="/mydocker/caddy/data/caddy/certificates"

    if [[ -d "$CADDY_CERTS_DIR" ]]; then
        # Find certificate files and check expiration
        CERTS_EXPIRING=0
        CERTS_OK=0

        while IFS= read -r cert; do
            if [[ -f "$cert" ]]; then
                EXPIRY=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
                if [[ -n "$EXPIRY" ]]; then
                    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
                    NOW_EPOCH=$(date +%s)
                    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

                    if [[ $DAYS_LEFT -lt $CERT_WARNING_DAYS ]]; then
                        ((CERTS_EXPIRING++))
                    else
                        ((CERTS_OK++))
                    fi
                fi
            fi
        done < <(find "$CADDY_CERTS_DIR" -name "*.crt" 2>/dev/null)

        if [[ $CERTS_EXPIRING -gt 0 ]]; then
            warn "$CERTS_EXPIRING certificates expiring within ${CERT_WARNING_DAYS} days" "cert_expiry" "Check Caddy auto-renewal"
        elif [[ $CERTS_OK -gt 0 ]]; then
            pass "$CERTS_OK certificates valid (>${CERT_WARNING_DAYS} days)" "cert_expiry"
        else
            info "No certificates found to check"
        fi
    else
        skip "Caddy certificates directory not found" "cert_expiry"
    fi

    subheader "Log Retention"

    # Check log directory sizes
    LOG_DIRS=(
        "/var/log:system_logs"
        "$HOME/logs:user_logs"
        "/mydocker/loki/data:loki_data"
    )

    for entry in "${LOG_DIRS[@]}"; do
        dir="${entry%%:*}"
        name="${entry##*:}"
        if [[ -d "$dir" ]]; then
            SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
            info "$dir: $SIZE"
        fi
    done
}

# ============================================================================
# SECURITY CHECKS
# ============================================================================

check_security() {
    header "SECURITY AUDIT"

    subheader "Authentication Failures"

    # Check auth.log for recent failures (last 7 days)
    if [[ -f /var/log/auth.log ]]; then
        FAILED_SSH=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
        FAILED_SUDO=$(grep -c "authentication failure" /var/log/auth.log 2>/dev/null || echo "0")

        info "Failed SSH attempts (all time in log): $FAILED_SSH"
        info "Sudo auth failures (all time in log): $FAILED_SUDO"

        if [[ $FAILED_SSH -gt 100 ]]; then
            warn "High number of failed SSH attempts" "auth_ssh_failures" "$FAILED_SSH attempts"
        else
            pass "SSH failures within normal range" "auth_ssh_failures"
        fi
    else
        skip "auth.log not accessible" "auth_ssh_failures"
    fi

    subheader "Docker Security"

    # Check for containers running as root
    ROOT_CONTAINERS=$(docker ps --quiet | xargs -r docker inspect --format '{{.Name}}: {{.Config.User}}' 2>/dev/null | grep -c ": $" || echo "0")
    info "Containers with default (root) user: $ROOT_CONTAINERS"

    # Check for privileged containers
    PRIVILEGED=$(docker ps --quiet | xargs -r docker inspect --format '{{.Name}}: {{.HostConfig.Privileged}}' 2>/dev/null | grep -c "true" || echo "0")
    if [[ $PRIVILEGED -gt 0 ]]; then
        warn "$PRIVILEGED privileged containers running" "docker_privileged" "Review security requirements"
    else
        pass "No privileged containers" "docker_privileged"
    fi

    subheader "File Permissions"

    # Check SSH key permissions
    if [[ -d "$HOME/.ssh" ]]; then
        BAD_PERMS=$(find "$HOME/.ssh" -type f -perm /077 2>/dev/null | wc -l)
        if [[ $BAD_PERMS -gt 0 ]]; then
            warn "$BAD_PERMS SSH files with insecure permissions" "ssh_permissions" "Run: chmod 600 ~/.ssh/*"
        else
            pass "SSH file permissions OK" "ssh_permissions"
        fi
    fi

    # Check for world-writable files in sensitive locations
    WORLD_WRITABLE=$(find /mydocker -type f -perm -002 2>/dev/null | wc -l | tr -d '[:space:]') || WORLD_WRITABLE="0"
    if [[ "$WORLD_WRITABLE" -gt 0 ]] 2>/dev/null; then
        warn "$WORLD_WRITABLE world-writable files in /mydocker" "world_writable" "Review file permissions"
    else
        pass "No world-writable files in /mydocker" "world_writable"
    fi
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_summary() {
    header "HEALTH CHECK SUMMARY"

    TOTAL=$((CHECKS_PASSED + CHECKS_WARNED + CHECKS_FAILED + CHECKS_SKIPPED))

    log ""
    log "${GREEN}Passed:  $CHECKS_PASSED${NC}"
    log "${YELLOW}Warnings: $CHECKS_WARNED${NC}"
    log "${RED}Failed:  $CHECKS_FAILED${NC}"
    log "${MAGENTA}Skipped: $CHECKS_SKIPPED${NC}"
    log ""
    log "Total checks: $TOTAL"
    log ""

    # Calculate overall health score
    if [[ $TOTAL -gt 0 ]]; then
        SCORE=$(( (CHECKS_PASSED * 100) / (TOTAL - CHECKS_SKIPPED) ))
    else
        SCORE=0
    fi

    log "Health Score: ${SCORE}%"
    log ""

    # Determine overall status
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        log "${RED}${BOLD}OVERALL STATUS: CRITICAL - $CHECKS_FAILED issues require attention${NC}"
        OVERALL_STATUS="critical"
    elif [[ $CHECKS_WARNED -gt 0 ]]; then
        log "${YELLOW}${BOLD}OVERALL STATUS: WARNING - $CHECKS_WARNED items need review${NC}"
        OVERALL_STATUS="warning"
    else
        log "${GREEN}${BOLD}OVERALL STATUS: HEALTHY - All systems operational${NC}"
        OVERALL_STATUS="healthy"
    fi

    log ""
    log "Report saved to: $REPORT_FILE"

    # Send summary to Loki
    send_to_loki "$OVERALL_STATUS" "Weekly health check completed: score=$SCORE%, passed=$CHECKS_PASSED, warned=$CHECKS_WARNED, failed=$CHECKS_FAILED"
}

generate_json_report() {
    local json_results=$(IFS=,; echo "${JSON_RESULTS[*]}")

    cat > "$JSON_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "summary": {
        "passed": $CHECKS_PASSED,
        "warnings": $CHECKS_WARNED,
        "failed": $CHECKS_FAILED,
        "skipped": $CHECKS_SKIPPED,
        "total": $((CHECKS_PASSED + CHECKS_WARNED + CHECKS_FAILED + CHECKS_SKIPPED)),
        "score": $(( (CHECKS_PASSED * 100) / (CHECKS_PASSED + CHECKS_WARNED + CHECKS_FAILED) )),
        "status": "$OVERALL_STATUS"
    },
    "checks": [$json_results]
}
EOF

    if [[ "$OUTPUT_JSON" == "true" ]]; then
        cat "$JSON_FILE"
    fi

    log ""
    log "JSON report: $JSON_FILE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    ensure_dirs

    log ""
    log "${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
    log "${BOLD}║           WEEKLY INFRASTRUCTURE HEALTH CHECK                     ║${NC}"
    log "${BOLD}║           $(date '+%Y-%m-%d %H:%M:%S')                                  ║${NC}"
    log "${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
    log ""

    case "$TARGET_SECTION" in
        all)
            check_backups
            check_docker
            check_credentials
            check_logging
            check_network
            check_storage
            check_security
            ;;
        backup)
            check_backups
            ;;
        docker)
            check_docker
            ;;
        credentials)
            check_credentials
            ;;
        logging)
            check_logging
            ;;
        network)
            check_network
            ;;
        storage)
            check_storage
            ;;
        security)
            check_security
            ;;
        *)
            echo "Unknown section: $TARGET_SECTION"
            echo "Valid sections: all, backup, docker, credentials, logging, network, storage, security"
            exit 1
            ;;
    esac

    generate_summary
    generate_json_report

    # Update priorities file with health check findings (only for full checks)
    if [[ "$TARGET_SECTION" == "all" ]]; then
        UPDATE_SCRIPT="$HOME/Scripts/update-priorities-health.sh"
        if [[ -x "$UPDATE_SCRIPT" ]]; then
            log ""
            log "Updating priorities with health check findings..."
            "$UPDATE_SCRIPT" "$JSON_FILE" 2>/dev/null && log "Priorities updated successfully." || log "Note: Could not update priorities file."
        fi
    fi

    # Exit with appropriate code
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        exit 2
    elif [[ $CHECKS_WARNED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main
main "$@"

#!/bin/bash
#
# Weekly Infrastructure Health Check
#
# Comprehensive validation of backups, services, credentials, and system health.
#
# Usage: ./weekly-health-check.sh [--json] [--quiet] [--section SECTION]
#
# Sections: all, backup, docker, credentials, logging, network, storage, security
#
# Configuration: Copy config.sh.template to config.sh and customize.
#

# Note: Not using 'set -e' to allow graceful error handling in checks
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration if available
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi

# ============================================================================
# CONFIGURATION (override in config.sh)
# ============================================================================

REPORT_DIR="${REPORT_DIR:-$HOME/logs/weekly-health}"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/health-report-$TIMESTAMP.txt"
JSON_FILE="$REPORT_DIR/health-report-$TIMESTAMP.json"
LOKI_URL="${LOKI_URL:-http://localhost:3100/loki/api/v1/push}"

# Thresholds (can override in config.sh)
BACKUP_MAX_AGE_HOURS="${BACKUP_MAX_AGE_HOURS:-48}"
DISK_WARNING_PERCENT="${DISK_WARNING_PERCENT:-80}"
DISK_CRITICAL_PERCENT="${DISK_CRITICAL_PERCENT:-90}"
CERT_WARNING_DAYS="${CERT_WARNING_DAYS:-30}"

# Infrastructure hosts - override in config.sh
# Format: declare -A INFRASTRUCTURE_HOSTS=( ["Name"]="IP" )
if [[ -z "${INFRASTRUCTURE_HOSTS+x}" ]]; then
    declare -A INFRASTRUCTURE_HOSTS=(
        ["localhost"]="127.0.0.1"
    )
fi

# Critical services to check - override in config.sh
if [[ -z "${CRITICAL_SERVICES+x}" ]]; then
    CRITICAL_SERVICES=("caddy" "postgres")
fi

# Public URL to verify - override in config.sh
PUBLIC_HEALTH_URL="${PUBLIC_HEALTH_URL:-}"

# Restic configuration - override in config.sh
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$HOME/.restic/backup-password.txt}"

# SSH hosts to check - override in config.sh
if [[ -z "${SSH_HOSTS+x}" ]]; then
    SSH_HOSTS=()
fi

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
    if [[ -n "${3:-}" ]]; then
        log "    ${YELLOW}↳ $3${NC}"
    fi
    ((CHECKS_WARNED++))
    add_json_result "$2" "warn" "$1" "${3:-}"
}

fail() {
    log "${RED}✗${NC} $1"
    if [[ -n "${3:-}" ]]; then
        log "    ${RED}↳ $3${NC}"
    fi
    ((CHECKS_FAILED++))
    add_json_result "$2" "fail" "$1" "${3:-}"
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
                    \"host\": \"$(hostname)\",
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

    if [[ -n "$RESTIC_REPOSITORY" ]]; then
        export RESTIC_REPOSITORY
        export RESTIC_PASSWORD_FILE

        if [[ -f "$RESTIC_PASSWORD_FILE" ]]; then
            if restic snapshots --latest 1 &>/dev/null; then
                pass "Restic repository accessible" "restic_connectivity"

                # Check last backup age
                LAST_BACKUP=""
                RESTIC_JSON=$(restic snapshots --latest 1 --json 2>/dev/null) || true
                if [[ -n "$RESTIC_JSON" && "$RESTIC_JSON" != "null" && "$RESTIC_JSON" != "[]" ]]; then
                    LAST_BACKUP=$(echo "$RESTIC_JSON" | jq -r '.[0].time // empty' 2>/dev/null) || true
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
                        pass "Restic backup exists" "restic_age"
                    fi

                    # Check snapshot count
                    SNAPSHOT_COUNT=$(restic snapshots --json 2>/dev/null | jq 'length' 2>/dev/null) || SNAPSHOT_COUNT="unknown"
                    info "Total snapshots: $SNAPSHOT_COUNT"
                else
                    warn "No Restic snapshots found" "restic_snapshots" "Repository exists but empty"
                fi
            else
                fail "Cannot access Restic repository" "restic_connectivity" "Check mount and credentials"
            fi
        else
            skip "Restic password file not found" "restic_connectivity"
        fi
    else
        skip "Restic repository not configured" "restic_connectivity"
    fi

    # Check systemd timer if available
    if systemctl is-active --quiet restic-backup.timer 2>/dev/null; then
        pass "Restic backup timer is active" "restic_timer"
    else
        info "Restic backup timer not configured or inactive"
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

    for service in "${CRITICAL_SERVICES[@]}"; do
        if docker ps --format '{{.Names}}' | grep -qE "^${service}$|_${service}_|${service}_|${service}-"; then
            CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "^${service}$|_${service}_|${service}_|${service}-" | head -1)
            UPTIME=$(docker ps --format '{{.Status}}' --filter "name=$CONTAINER_NAME" | head -1)
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null) || HEALTH="none"
            if [[ "$HEALTH" == "unhealthy" ]]; then
                warn "$service: running but UNHEALTHY" "docker_$service" "Health check failing"
            else
                pass "$service: running ($UPTIME)" "docker_$service"
            fi
        else
            fail "$service: NOT RUNNING" "docker_$service" "Container not found"
        fi
    done

    # Watchtower status
    subheader "Auto-Update (Watchtower)"

    if docker ps --format '{{.Names}}' | grep -q watchtower; then
        pass "Watchtower is running" "watchtower"
    else
        info "Watchtower is not running (auto-updates disabled)"
    fi
}

# ============================================================================
# CREDENTIAL & API VALIDATION
# ============================================================================

check_http_endpoint() {
    local url="$1"
    local name="$2"
    local check_id="$3"
    local severity="${4:-fail}"
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
        case $curl_exit in
            6)  detail="Could not resolve host" ;;
            7)  detail="Connection refused" ;;
            28) detail="Connection timed out" ;;
            35) detail="SSL/TLS error" ;;
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

    subheader "Local API Health Checks"

    # Common local services - adjust ports as needed
    check_http_endpoint "http://localhost:5678/healthz" "n8n API" "api_n8n" "warn"
    check_http_endpoint "http://localhost:3000/api/health" "Grafana API" "api_grafana" "warn"
    check_http_endpoint "http://localhost:3100/ready" "Loki API" "api_loki" "warn"
    check_http_endpoint "http://localhost:9090/-/healthy" "Prometheus API" "api_prometheus" "warn"

    subheader "Database Connectivity"

    # PostgreSQL check - looks for any postgres container
    PG_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i postgres | head -1)
    if [[ -n "$PG_CONTAINERS" ]]; then
        if docker exec "$PG_CONTAINERS" pg_isready -U postgres &>/dev/null; then
            pass "PostgreSQL ($PG_CONTAINERS) accepting connections" "db_postgres"
        else
            fail "PostgreSQL ($PG_CONTAINERS) not responding" "db_postgres" "pg_isready failed"
        fi
    else
        info "No PostgreSQL container found"
    fi

    subheader "External Connectivity"

    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        pass "Internet connectivity OK" "net_internet"
    else
        fail "Internet connectivity FAILED" "net_internet" "Cannot reach external networks"
    fi

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

    if curl -s "http://localhost:3100/ready" 2>/dev/null | grep -q "ready"; then
        pass "Loki is ready" "loki_ready"
    else
        warn "Loki is not ready or not installed" "loki_ready" "Check Loki container"
    fi

    subheader "Promtail Status"

    if curl -sf "http://localhost:9080/ready" &>/dev/null; then
        pass "Promtail is ready" "promtail_ready"
    else
        info "Promtail not responding (may not be installed)"
    fi

    subheader "Audit Log System"

    AIFRED_DIR="${AIFRED_DIR:-$HOME/Code/AIfred}"
    AUDIT_LOG="$AIFRED_DIR/.claude/logs/audit.jsonl"
    if [[ -f "$AUDIT_LOG" ]]; then
        AUDIT_SIZE=$(du -h "$AUDIT_LOG" | cut -f1)
        AUDIT_LINES=$(wc -l < "$AUDIT_LOG")
        pass "Audit log exists ($AUDIT_SIZE, $AUDIT_LINES entries)" "audit_log"
    else
        info "Audit log not found at $AUDIT_LOG"
    fi
}

# ============================================================================
# NETWORK & SSH CONNECTIVITY
# ============================================================================

check_network() {
    header "NETWORK & SSH CONNECTIVITY"

    subheader "Infrastructure Hosts"

    for host in "${!INFRASTRUCTURE_HOSTS[@]}"; do
        ip="${INFRASTRUCTURE_HOSTS[$host]}"
        if ping -c 1 -W 3 "$ip" &>/dev/null; then
            pass "$host ($ip) is reachable" "ping_${host,,}"
        else
            warn "$host ($ip) is unreachable" "ping_${host,,}" "Host not responding to ping"
        fi
    done

    subheader "SSH Connectivity"

    for ssh_host in "${SSH_HOSTS[@]}"; do
        SSH_ERR=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$ssh_host" "echo OK" 2>&1)
        SSH_EXIT=$?
        if [[ $SSH_EXIT -eq 0 ]]; then
            pass "SSH to $ssh_host working" "ssh_${ssh_host,,}"
        else
            if echo "$SSH_ERR" | grep -qi "permission denied"; then
                warn "SSH to $ssh_host failed" "ssh_${ssh_host,,}" "Permission denied - check keys"
            else
                warn "SSH to $ssh_host failed" "ssh_${ssh_host,,}" "Connection failed"
            fi
        fi
    done

    if [[ ${#SSH_HOSTS[@]} -eq 0 ]]; then
        info "No SSH hosts configured in config.sh"
    fi

    subheader "NFS Mounts"

    # Check for any NFS mounts
    NFS_MOUNTS=$(mount | grep -c "nfs" || echo "0")
    if [[ $NFS_MOUNTS -gt 0 ]]; then
        pass "$NFS_MOUNTS NFS mount(s) active" "nfs_mounts"
    else
        info "No NFS mounts detected"
    fi

    subheader "Reverse Proxy"

    # Check Caddy admin API
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:2019/config/" 2>&1 | grep -q "^2"; then
        pass "Caddy admin API responding" "caddy_admin"
    else
        info "Caddy admin API not responding (may be disabled)"
    fi

    # Check public endpoint if configured
    if [[ -n "$PUBLIC_HEALTH_URL" ]]; then
        check_http_endpoint "$PUBLIC_HEALTH_URL" "Public endpoint" "public_endpoint" "warn"
    fi
}

# ============================================================================
# STORAGE & CERTIFICATES
# ============================================================================

check_storage() {
    header "STORAGE & CERTIFICATES"

    subheader "Disk Usage"

    declare -A FILESYSTEMS=(
        ["/"]="root"
        ["/home"]="home"
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

    subheader "Docker Storage"

    DOCKER_USAGE=$(docker system df --format '{{.Type}}: {{.Size}}' 2>/dev/null | tr '\n' ', ')
    info "Docker usage: $DOCKER_USAGE"

    DANGLING_IMAGES=$(docker images -f "dangling=true" -q | wc -l)
    DANGLING_VOLUMES=$(docker volume ls -f "dangling=true" -q | wc -l)

    if [[ $DANGLING_IMAGES -gt 10 ]] || [[ $DANGLING_VOLUMES -gt 5 ]]; then
        warn "Docker cleanup recommended ($DANGLING_IMAGES dangling images, $DANGLING_VOLUMES dangling volumes)" "docker_cleanup" "Run docker system prune"
    else
        pass "Docker storage clean ($DANGLING_IMAGES dangling images)" "docker_cleanup"
    fi
}

# ============================================================================
# SECURITY CHECKS
# ============================================================================

check_security() {
    header "SECURITY AUDIT"

    subheader "Authentication Failures"

    if [[ -f /var/log/auth.log ]]; then
        FAILED_SSH=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
        info "Failed SSH attempts (in current log): $FAILED_SSH"

        if [[ $FAILED_SSH -gt 100 ]]; then
            warn "High number of failed SSH attempts" "auth_ssh_failures" "$FAILED_SSH attempts"
        else
            pass "SSH failures within normal range" "auth_ssh_failures"
        fi
    else
        info "auth.log not accessible (may need sudo)"
    fi

    subheader "Docker Security"

    PRIVILEGED=$(docker ps --quiet | xargs -r docker inspect --format '{{.Name}}: {{.HostConfig.Privileged}}' 2>/dev/null | grep -c "true" || echo "0")
    if [[ $PRIVILEGED -gt 0 ]]; then
        warn "$PRIVILEGED privileged containers running" "docker_privileged" "Review security requirements"
    else
        pass "No privileged containers" "docker_privileged"
    fi

    subheader "File Permissions"

    if [[ -d "$HOME/.ssh" ]]; then
        BAD_PERMS=$(find "$HOME/.ssh" -type f -perm /077 2>/dev/null | wc -l)
        if [[ $BAD_PERMS -gt 0 ]]; then
            warn "$BAD_PERMS SSH files with insecure permissions" "ssh_permissions" "Run: chmod 600 ~/.ssh/*"
        else
            pass "SSH file permissions OK" "ssh_permissions"
        fi
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

    if [[ $TOTAL -gt 0 ]] && [[ $((TOTAL - CHECKS_SKIPPED)) -gt 0 ]]; then
        SCORE=$(( (CHECKS_PASSED * 100) / (TOTAL - CHECKS_SKIPPED) ))
    else
        SCORE=0
    fi

    log "Health Score: ${SCORE}%"
    log ""

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
        "score": $SCORE,
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

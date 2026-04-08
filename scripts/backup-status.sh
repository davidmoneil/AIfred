#!/bin/bash
# Script: backup-status.sh
# Purpose: Show status of Restic backups
# Usage: ./backup-status.sh [options]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -uo pipefail

# Configuration — override via env or scripts/config.sh
RESTIC_REPO="${RESTIC_REPO:-sftp:backup-host:D:/Restic/primary-backups}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-${HOME}/.restic-password}"
SCRIPTS_DIR="${SCRIPTS_DIR:-${HOME}/Scripts}"

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

Show status of Restic backup system.

Options:
    -l, --list N      List last N snapshots (default: 5)
    -s, --stats       Show repository statistics
    -c, --check       Verify repository integrity
    -j, --json        JSON output
    -q, --quiet       Minimal output (just status)
    -h, --help        Show this help

Examples:
    $(basename "$0")              # Quick status
    $(basename "$0") --list 10    # Last 10 snapshots
    $(basename "$0") --stats      # Repository stats
    $(basename "$0") --check      # Verify integrity

Exit Codes:
    0  Backups healthy
    1  Configuration issue
    2  Backup overdue (>48h)
    3  Repository issue
EOF
}

# Logging
log_info() { [[ "$QUIET" == false ]] && echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { [[ "$QUIET" == false ]] && echo -e "${GREEN}✓${NC} $1"; }
log_warning() { [[ "$QUIET" == false ]] && echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { [[ "$QUIET" == false ]] && echo -e "${RED}✗${NC} $1"; }

# Parse arguments
LIST_COUNT=5
SHOW_STATS=false
CHECK_REPO=false
JSON_OUTPUT=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -l|--list) LIST_COUNT="$2"; shift 2 ;;
        -s|--stats) SHOW_STATS=true; shift ;;
        -c|--check) CHECK_REPO=true; shift ;;
        -j|--json) JSON_OUTPUT=true; QUIET=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -*) log_error "Unknown option: $1"; show_help; exit 1 ;;
        *) shift ;;
    esac
done

# Check prerequisites
if [[ ! -f "$RESTIC_PASSWORD_FILE" ]]; then
    log_error "Password file not found: $RESTIC_PASSWORD_FILE"
    exit 1
fi

# Export for restic
export RESTIC_REPOSITORY="$RESTIC_REPO"
export RESTIC_PASSWORD_FILE="$RESTIC_PASSWORD_FILE"

# Check if restic is available
if ! command -v restic &>/dev/null; then
    log_error "Restic not installed"
    exit 1
fi

# Header
if [[ "$QUIET" == false ]] && [[ "$JSON_OUTPUT" == false ]]; then
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              BACKUP STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Repository:${NC} $RESTIC_REPO"
    echo ""
fi

# Get snapshots
SNAPSHOTS=$(restic snapshots --json 2>/dev/null)

if [[ -z "$SNAPSHOTS" ]] || [[ "$SNAPSHOTS" == "null" ]] || [[ "$SNAPSHOTS" == "[]" ]]; then
    log_error "No snapshots found or cannot connect to repository"
    exit 3
fi

# Parse latest snapshot
LATEST=$(echo "$SNAPSHOTS" | jq -r '.[-1]')
LATEST_TIME=$(echo "$LATEST" | jq -r '.time')
LATEST_ID=$(echo "$LATEST" | jq -r '.short_id')
SNAPSHOT_COUNT=$(echo "$SNAPSHOTS" | jq 'length')

# Calculate age
LATEST_EPOCH=$(date -d "$LATEST_TIME" +%s 2>/dev/null || echo "0")
NOW_EPOCH=$(date +%s)
AGE_HOURS=$(( (NOW_EPOCH - LATEST_EPOCH) / 3600 ))

# Determine status
STATUS="healthy"
if [[ $AGE_HOURS -gt 48 ]]; then
    STATUS="overdue"
elif [[ $AGE_HOURS -gt 24 ]]; then
    STATUS="warning"
fi

# JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
    cat << JSON
{
  "status": "$STATUS",
  "repository": "$RESTIC_REPO",
  "latest_snapshot": {
    "id": "$LATEST_ID",
    "time": "$LATEST_TIME",
    "age_hours": $AGE_HOURS
  },
  "total_snapshots": $SNAPSHOT_COUNT
}
JSON
    exit $([[ "$STATUS" == "overdue" ]] && echo 2 || echo 0)
fi

# Display status
case "$STATUS" in
    healthy)
        log_success "Backups healthy"
        ;;
    warning)
        log_warning "Last backup was ${AGE_HOURS}h ago"
        ;;
    overdue)
        log_error "Backups overdue! Last backup was ${AGE_HOURS}h ago"
        ;;
esac

echo ""
echo -e "${BLUE}Latest Snapshot:${NC}"
echo "  ID:   $LATEST_ID"
echo "  Time: $LATEST_TIME"
echo "  Age:  ${AGE_HOURS} hours"
echo ""
echo -e "${BLUE}Total Snapshots:${NC} $SNAPSHOT_COUNT"

# List snapshots
if [[ "$QUIET" == false ]]; then
    echo ""
    echo -e "${CYAN}─── Recent Snapshots (last $LIST_COUNT) ───${NC}"
    echo ""
    restic snapshots --last "$LIST_COUNT" 2>/dev/null | tail -n +3
fi

# Repository stats
if [[ "$SHOW_STATS" == true ]]; then
    echo ""
    echo -e "${CYAN}─── Repository Statistics ───${NC}"
    echo ""
    restic stats 2>/dev/null
fi

# Check integrity
if [[ "$CHECK_REPO" == true ]]; then
    echo ""
    echo -e "${CYAN}─── Integrity Check ───${NC}"
    echo ""
    if restic check 2>/dev/null; then
        log_success "Repository integrity verified"
    else
        log_error "Repository integrity check failed"
        exit 3
    fi
fi

# Footer
if [[ "$QUIET" == false ]]; then
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

    # Next scheduled backup
    if systemctl --user is-active restic-backup.timer &>/dev/null; then
        NEXT=$(systemctl --user list-timers restic-backup.timer --no-pager 2>/dev/null | grep restic | awk '{print $1, $2}')
        echo -e "${BLUE}Next scheduled:${NC} $NEXT"
    fi

    # Manual backup command
    echo -e "${BLUE}Manual backup:${NC} ~/Scripts/restic-backup.sh"
    echo ""
fi

# Exit code based on status
case "$STATUS" in
    overdue) exit 2 ;;
    *) exit 0 ;;
esac

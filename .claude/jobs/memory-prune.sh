#!/bin/bash
#
# memory-prune.sh - Identify and archive stale Memory MCP entities
#
# Purpose: Analyze entity-metadata.json to find entities not accessed
#          in the configured retention period, then archive them.
#
# Usage:
#   ./memory-prune.sh              # Dry run - show what would be archived
#   ./memory-prune.sh --execute    # Archive stale entities
#   ./memory-prune.sh --days 60    # Custom retention (default: 90)
#
# Note: This script identifies and archives stale entities, but actual
#       deletion from Memory MCP requires a Claude Code session.
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
METADATA_FILE="$PROJECT_ROOT/.claude/agents/memory/entity-metadata.json"
ARCHIVE_DIR="$PROJECT_ROOT/.claude/archive/memory"
LOG_FILE="$PROJECT_ROOT/.claude/jobs/logs/memory-prune.log"

# Defaults
RETENTION_DAYS=90
DRY_RUN=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $1"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

log_info() { log "${BLUE}[INFO]${NC} $1"; }
log_warn() { log "${YELLOW}[WARN]${NC} $1"; }
log_pass() { log "${GREEN}[PASS]${NC} $1"; }
log_fail() { log "${RED}[FAIL]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --execute)
            DRY_RUN=false
            shift
            ;;
        --days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--execute] [--days N]"
            echo ""
            echo "Options:"
            echo "  --execute    Actually archive (default is dry run)"
            echo "  --days N     Retention period in days (default: 90)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check dependencies
if ! command -v jq &> /dev/null; then
    log_fail "jq is required but not installed"
    exit 1
fi

# Check metadata file exists
if [[ ! -f "$METADATA_FILE" ]]; then
    log_warn "No metadata file found at $METADATA_FILE"
    log_info "Memory maintenance hook may not have run yet"
    exit 0
fi

log_info "Memory Entity Pruning Analysis"
log_info "==============================="
log_info "Retention period: $RETENTION_DAYS days"
log_info "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
echo ""

# Calculate cutoff date
CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${RETENTION_DAYS}d '+%Y-%m-%d')
log_info "Cutoff date: $CUTOFF_DATE (entities not accessed since)"
echo ""

# Read metadata and find stale entities
STALE_ENTITIES=()
ACTIVE_ENTITIES=()
TOTAL_ENTITIES=0

while IFS= read -r entity; do
    TOTAL_ENTITIES=$((TOTAL_ENTITIES + 1))
    name=$(echo "$entity" | jq -r '.name')
    last_accessed=$(echo "$entity" | jq -r '.lastAccessed')
    access_count=$(echo "$entity" | jq -r '.accessCount')
    
    if [[ "$last_accessed" < "$CUTOFF_DATE" ]]; then
        STALE_ENTITIES+=("$name|$last_accessed|$access_count")
    else
        ACTIVE_ENTITIES+=("$name|$last_accessed|$access_count")
    fi
done < <(jq -r '.entities | to_entries[] | {name: .key, lastAccessed: .value.lastAccessed, accessCount: .value.accessCount} | @json' "$METADATA_FILE" 2>/dev/null || echo "")

# Report findings
log_info "Entity Summary:"
log_info "  Total tracked: $TOTAL_ENTITIES"
log_info "  Active (recent): ${#ACTIVE_ENTITIES[@]}"
log_info "  Stale (>${RETENTION_DAYS}d): ${#STALE_ENTITIES[@]}"
echo ""

if [[ ${#STALE_ENTITIES[@]} -eq 0 ]]; then
    log_pass "No stale entities found - memory is healthy!"
    exit 0
fi

# Show stale entities
log_warn "Stale Entities (candidates for archival):"
echo ""
printf "%-50s %-12s %s\n" "Entity Name" "Last Access" "Count"
printf "%-50s %-12s %s\n" "-------------------------------------------" "------------" "-----"
for entry in "${STALE_ENTITIES[@]}"; do
    IFS='|' read -r name last_accessed access_count <<< "$entry"
    printf "%-50s %-12s %s\n" "${name:0:50}" "$last_accessed" "$access_count"
done
echo ""

# Archive if executing
if [[ "$DRY_RUN" = false ]]; then
    mkdir -p "$ARCHIVE_DIR"
    ARCHIVE_FILE="$ARCHIVE_DIR/$(date '+%Y-%m')-archive.json"
    
    log_info "Archiving stale entities to: $ARCHIVE_FILE"
    
    # Create or append to archive
    if [[ -f "$ARCHIVE_FILE" ]]; then
        EXISTING=$(cat "$ARCHIVE_FILE")
    else
        EXISTING='{"archived_entities":[],"archive_date":"","retention_days":0}'
    fi
    
    # Build new archive entry
    ARCHIVE_ENTRY=$(jq -n \
        --arg date "$(date -Iseconds)" \
        --arg retention "$RETENTION_DAYS" \
        --argjson entities "$(printf '%s\n' "${STALE_ENTITIES[@]}" | jq -R 'split("|") | {name: .[0], lastAccessed: .[1], accessCount: (.[2] | tonumber)}' | jq -s '.')" \
        '{
            archive_date: $date,
            retention_days: ($retention | tonumber),
            entities: $entities
        }')
    
    # Merge with existing
    echo "$EXISTING" | jq --argjson new "$ARCHIVE_ENTRY" '.archived_entities += [$new]' > "$ARCHIVE_FILE"
    
    log_pass "Archived ${#STALE_ENTITIES[@]} entities"
    echo ""
    log_info "Next Steps:"
    log_info "  1. Review archive: $ARCHIVE_FILE"
    log_info "  2. In a Claude session, run:"
    log_info "     mcp__mcp-gateway__delete_entities with entity names"
    log_info "  3. Or use /memory-cleanup command (if created)"
else
    echo ""
    log_info "DRY RUN - No changes made"
    log_info "Run with --execute to archive stale entities"
fi

echo ""
log_info "Pruning analysis complete"

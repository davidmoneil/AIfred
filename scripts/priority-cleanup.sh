#!/bin/bash
#
# Priority Cleanup Script
# Hybrid trigger system for maintaining current-priorities.md
#
# - Detects oversized file, stale items, completed items in wrong sections
# - Auto-archives completed items older than threshold
# - Triggers Claude review only when judgment needed
#
# Usage: ./priority-cleanup.sh [--dry-run] [--verbose] [--force-claude]
#
# Pattern: Capability Layering (bash detection + auto-archive, Claude for judgment)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PRIORITIES_FILE="$PROJECT_DIR/.claude/context/projects/current-priorities.md"
ARCHIVE_DIR="$PROJECT_DIR/.claude/context/archive"
TIMESTAMP=$(date '+%Y-%m-%d')
MONTH_STAMP=$(date '+%Y-%m')

# Thresholds
MAX_LINES=200              # Target file size
WARN_LINES=300             # Warning threshold
ARCHIVE_AGE_DAYS=30        # Days before completed items get archived
STALE_COMPLETED_DAYS=14    # Days a "COMPLETE" item can stay in In Progress

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
DRY_RUN=false
VERBOSE=false
FORCE_CLAUDE=false

# Counters
ISSUES_FOUND=0
ITEMS_ARCHIVED=0

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --force-claude) FORCE_CLAUDE=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--verbose] [--force-claude]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Show what would be done without making changes"
            echo "  --verbose       Show detailed output"
            echo "  --force-claude  Force Claude review even if no issues"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo -e "$1"
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[verbose]${NC} $1"
    fi
}

warn() {
    echo -e "${YELLOW}[warn]${NC} $1"
    ((ISSUES_FOUND++))
}

error() {
    echo -e "${RED}[error]${NC} $1"
    ((ISSUES_FOUND++))
}

success() {
    echo -e "${GREEN}[ok]${NC} $1"
}

# ============================================================================
# DETECTION FUNCTIONS
# ============================================================================

check_file_size() {
    local line_count
    line_count=$(wc -l < "$PRIORITIES_FILE")

    verbose "File size: $line_count lines (target: <$MAX_LINES)"

    if [[ $line_count -gt $WARN_LINES ]]; then
        error "File is $line_count lines (target: <$MAX_LINES, warning: >$WARN_LINES)"
        return 1
    elif [[ $line_count -gt $MAX_LINES ]]; then
        warn "File is $line_count lines (target: <$MAX_LINES)"
        return 1
    else
        success "File size OK: $line_count lines"
        return 0
    fi
}

check_completed_in_progress() {
    # Find items marked COMPLETE that are still in "In Progress" section
    local completed_items
    completed_items=$(grep -n "COMPLETE" "$PRIORITIES_FILE" | grep -i "in progress\|status.*complete" | head -20 || true)

    if [[ -n "$completed_items" ]]; then
        warn "Found completed items still in 'In Progress' section:"
        echo "$completed_items" | while read -r line; do
            verbose "  $line"
        done
        return 1
    else
        success "No completed items in 'In Progress' section"
        return 0
    fi
}

check_resolved_sections() {
    # Find sections marked RESOLVED or MOSTLY RESOLVED that should be archived
    local resolved
    resolved=$(grep -n "RESOLVED\|MOSTLY RESOLVED" "$PRIORITIES_FILE" | head -10 || true)

    if [[ -n "$resolved" ]]; then
        warn "Found resolved sections that may need archiving:"
        echo "$resolved" | head -5
        return 1
    else
        success "No stale resolved sections"
        return 0
    fi
}

check_completed_section_size() {
    # Check if Completed section is too large
    local start_line end_line section_size

    start_line=$(grep -n "^## Completed" "$PRIORITIES_FILE" | head -1 | cut -d: -f1 || echo "0")

    if [[ "$start_line" == "0" ]]; then
        verbose "No Completed section found"
        return 0
    fi

    # Find next ## section or end of file
    end_line=$(tail -n +"$((start_line + 1))" "$PRIORITIES_FILE" | grep -n "^## " | head -1 | cut -d: -f1 || echo "0")

    if [[ "$end_line" == "0" ]]; then
        # Completed section goes to end of file
        section_size=$(($(wc -l < "$PRIORITIES_FILE") - start_line))
    else
        section_size=$((end_line - 1))
    fi

    verbose "Completed section: $section_size lines (starting at line $start_line)"

    if [[ $section_size -gt 100 ]]; then
        warn "Completed section is $section_size lines - should archive old entries"
        return 1
    else
        success "Completed section size OK: $section_size lines"
        return 0
    fi
}

check_old_dates() {
    # Find entries with dates older than threshold
    local cutoff_date old_entries
    cutoff_date=$(date -d "-${ARCHIVE_AGE_DAYS} days" '+%Y-%m-%d')

    # Look for date patterns like 2025-12-27 or (2025-12-27)
    old_entries=$(grep -oE "20[0-9]{2}-[01][0-9]-[0-3][0-9]" "$PRIORITIES_FILE" | sort -u | while read -r date; do
        if [[ "$date" < "$cutoff_date" ]]; then
            echo "$date"
        fi
    done || true)

    if [[ -n "$old_entries" ]]; then
        local count
        count=$(echo "$old_entries" | wc -l)
        warn "Found $count dates older than $ARCHIVE_AGE_DAYS days"
        verbose "Oldest dates: $(echo "$old_entries" | head -3 | tr '\n' ' ')"
        return 1
    else
        success "No entries older than $ARCHIVE_AGE_DAYS days"
        return 0
    fi
}

# ============================================================================
# ARCHIVE FUNCTIONS
# ============================================================================

ensure_archive_file() {
    local archive_file="$ARCHIVE_DIR/priorities-$MONTH_STAMP.md"

    if [[ ! -f "$archive_file" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            verbose "Would create archive file: $archive_file"
        else
            mkdir -p "$ARCHIVE_DIR"
            cat > "$archive_file" << EOF
# Archived Priorities - $MONTH_STAMP

Items archived from current-priorities.md

---

EOF
            verbose "Created archive file: $archive_file"
        fi
    fi

    echo "$archive_file"
}

archive_completed_section() {
    # Extract and archive the Completed section entries older than threshold
    local archive_file
    archive_file=$(ensure_archive_file)

    local start_line
    start_line=$(grep -n "^## Completed" "$PRIORITIES_FILE" | head -1 | cut -d: -f1 || echo "0")

    if [[ "$start_line" == "0" ]]; then
        verbose "No Completed section to archive"
        return 0
    fi

    # For now, just report - actual extraction requires more complex logic
    # This will be enhanced or deferred to Claude for judgment

    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would archive completed entries older than $ARCHIVE_AGE_DAYS days to $archive_file"
    else
        log "Archive operation requires Claude review for safe extraction"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${BLUE}  Priority Cleanup Check - $TIMESTAMP${NC}"
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
        log ""
    fi

    # Verify file exists
    if [[ ! -f "$PRIORITIES_FILE" ]]; then
        error "Priorities file not found: $PRIORITIES_FILE"
        log "Expected at: $PRIORITIES_FILE"
        log "This script expects .claude/context/projects/current-priorities.md in the project root."
        exit 1
    fi

    # Run all checks
    log "Running checks..."
    log ""

    check_file_size || true
    check_completed_in_progress || true
    check_resolved_sections || true
    check_completed_section_size || true
    check_old_dates || true

    log ""
    log "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Summary
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        log "${GREEN}All checks passed!${NC} No cleanup needed."

        if [[ "$FORCE_CLAUDE" == "true" ]]; then
            log ""
            log "Force Claude review requested..."
            trigger_claude_review "Routine review (forced)"
        fi
    else
        log "${YELLOW}Found $ISSUES_FOUND issue(s) requiring attention${NC}"
        log ""

        if [[ "$DRY_RUN" == "false" ]]; then
            log "Triggering Claude review for cleanup..."
            trigger_claude_review "Issues detected: file size, stale items, or archival needed"
        else
            log "Run without --dry-run to trigger Claude cleanup"
        fi
    fi

    log ""

    # Return exit code based on issues
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

trigger_claude_review() {
    local reason="$1"

    log ""
    log "${BLUE}Claude Review Trigger${NC}"
    log "Reason: $reason"
    log ""
    log "To perform cleanup, run:"
    log "  claude --print 'Review and clean up current-priorities.md. Archive completed items older than 30 days, move COMPLETE items from In Progress to archive, and reduce file to <200 lines while preserving active work.'"
    log ""
    log "Or use the slash command:"
    log "  /update-priorities review"
}

# Run main
main "$@"

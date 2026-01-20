#!/bin/bash
# Archive Session State Script
# Compresses and archives session-state.md at end of session
#
# Usage: ./archive-session-state.sh
#
# This script:
# 1. Archives the full current session-state.md with timestamp
# 2. Creates a compressed summary for history
# 3. Generates a fresh session-state.md template
#
# Created: 2026-01-20

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SESSION_STATE="$PROJECT_DIR/.claude/context/session-state.md"
ARCHIVE_DIR="$PROJECT_DIR/.claude/context/archive/session-state"
TIMESTAMP=$(date +"%Y-%m-%d")
ARCHIVE_FILE="$ARCHIVE_DIR/session-state-$TIMESTAMP.md"

# Create archive directory if needed
mkdir -p "$ARCHIVE_DIR"

# Check if session-state.md exists
if [[ ! -f "$SESSION_STATE" ]]; then
    echo "No session-state.md found at $SESSION_STATE"
    exit 1
fi

# Get current file size in lines
LINE_COUNT=$(wc -l < "$SESSION_STATE")
echo "Current session-state.md: $LINE_COUNT lines"

# Archive threshold (if more than 200 lines, archive)
THRESHOLD=200
if [[ $LINE_COUNT -lt $THRESHOLD ]]; then
    echo "Session state under threshold ($THRESHOLD lines). No archival needed."
    exit 0
fi

# Archive the full file
cp "$SESSION_STATE" "$ARCHIVE_FILE"
echo "Archived to: $ARCHIVE_FILE"

# Extract key information for compressed history
# - Current Work Status section (first ~50 lines)
# - Most recent session summary only
# - List of archive files for reference

# Create the new compressed session-state.md
cat > "$SESSION_STATE" << 'HEADER'
# Session State

**Purpose**: Track current work status across session interruptions.

**Update**: At key checkpoints - starting work, taking breaks, switching tasks, encountering blockers.

---

## Current Work Status

**Status**: 🟢 Idle

**Last Completed**: Session archived

**Current Blocker**: None

**Current Work**: Starting fresh session

HEADER

# Add compressed history section
cat >> "$SESSION_STATE" << HISTORY
---

## Archived History

Previous session histories have been archived. For full details, see:

HISTORY

# List archive files
for f in "$ARCHIVE_DIR"/*.md; do
    if [[ -f "$f" ]]; then
        basename "$f" | sed 's/^/- /'
    fi
done >> "$SESSION_STATE"

# Add recent summary from archived file (last major session summary only)
# Extract the first "### Session Summary" section
echo "" >> "$SESSION_STATE"
echo "### Most Recent Session (Compressed)" >> "$SESSION_STATE"
echo "" >> "$SESSION_STATE"

# Get the first session summary block (up to next "---" or "### Session")
awk '/^### Session Summary/{found=1} found{print} /^---$/ && found{exit}' "$ARCHIVE_FILE" | head -50 >> "$SESSION_STATE"

# Add template for new session
cat >> "$SESSION_STATE" << 'TEMPLATE'

---

## Current Session

*Use this section for detailed tracking of the current session.*

### Session Summary (DATE — Description)

**Status**: In Progress

| Task | Status |
|------|--------|
| ... | ... |

---

## Notes

**Branch**: Project_Aion
**Baseline**: main (read-only AIfred baseline)

---

*Session state initialized. Detailed history archived.*
TEMPLATE

NEW_LINE_COUNT=$(wc -l < "$SESSION_STATE")
echo "New session-state.md: $NEW_LINE_COUNT lines (reduced from $LINE_COUNT)"
echo "Archival complete."

#!/bin/bash
# preassemble-compression-input.sh — Pre-assemble all compression agent inputs
#
# Combines all files the compression agent would normally read individually
# into a single pre-assembled document. Applies RTK-inspired filtering:
#   - Index compression (names only from catalogs)
#   - Capability map reduction (id + when pairs only)
#   - Chat export truncation (last 40% only)
#   - Whitespace normalization
#   - Size capping (50K chars / ~12.5K tokens)
#
# Output: .claude/context/.compression-input-preassembled.md
#
# Part of Experiment 6 (preprocessing effect on compression time).
#
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
OUTPUT_FILE="$PROJECT_DIR/.claude/context/.compression-input-preassembled.md"
TMP_FILE="${OUTPUT_FILE}.tmp"
MAX_CHARS=50000

# ─── Helpers ────────────────────────────────────────────────────────────────
log() {
    echo "[$(date '+%H:%M:%S')] preassemble: $*" >&2
}

safe_cat() {
    # Cat a file if it exists, otherwise print fallback message
    local file="$1"
    local fallback="${2:-[File not found: $file]}"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        echo "$fallback"
    fi
}

collapse_blank_lines() {
    # Collapse runs of 3+ blank lines into 1
    awk 'NF{blank=0} !NF{blank++} blank<=1'
}

# ─── Assembly ───────────────────────────────────────────────────────────────
log "Assembling compression input..."
: > "$TMP_FILE"

{
    echo "# Compression Input (Pre-Assembled)"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # ── Foundation: CLAUDE.md (full — rules must be complete) ──
    echo "## Foundation: CLAUDE.md"
    echo ""
    safe_cat "$PROJECT_DIR/CLAUDE.md" "[CLAUDE.md not found]"
    echo ""
    echo ""

    # ── Foundation: Identity (full — persona must be complete) ──
    echo "## Foundation: Identity"
    echo ""
    safe_cat "$PROJECT_DIR/.claude/context/psyche/jarvis-identity.md" "[Identity file not found]"
    echo ""
    echo ""

    # ── Foundation: Capability Map (compressed — id + when pairs only) ──
    echo "## Foundation: Capability Map (IDs + Triggers Only)"
    echo ""
    capmap="$PROJECT_DIR/.claude/context/psyche/capability-map.yaml"
    if [[ -f "$capmap" ]]; then
        grep -E '^\s+- id:|^\s+when:' "$capmap" 2>/dev/null || echo "[No id/when entries found]"
    else
        echo "[Capability map not found]"
    fi
    echo ""
    echo ""

    # ── Foundation: Compaction Essentials (full) ──
    echo "## Foundation: Compaction Essentials"
    echo ""
    safe_cat "$PROJECT_DIR/.claude/context/compaction-essentials.md" "[Compaction essentials not found]"
    echo ""
    echo ""

    # ── Indexes (names only — RTK-style index compression) ──
    echo "## Indexes (Names Only)"
    echo ""

    echo "### Patterns"
    if [[ -f "$PROJECT_DIR/.claude/context/patterns/_index.md" ]]; then
        grep '^- ' "$PROJECT_DIR/.claude/context/patterns/_index.md" 2>/dev/null | head -60 || echo "[No patterns found]"
    else
        echo "[Pattern index not found]"
    fi
    echo ""

    echo "### Agents"
    if [[ -f "$PROJECT_DIR/.claude/agents/README.md" ]]; then
        grep '^- ' "$PROJECT_DIR/.claude/agents/README.md" 2>/dev/null | head -20 || echo "[No agents found]"
    else
        echo "[Agent README not found]"
    fi
    echo ""

    echo "### Commands"
    if [[ -f "$PROJECT_DIR/.claude/commands/README.md" ]]; then
        grep '^- ' "$PROJECT_DIR/.claude/commands/README.md" 2>/dev/null | head -50 || echo "[No commands found]"
    else
        echo "[Command README not found]"
    fi
    echo ""

    echo "### Skills"
    if [[ -f "$PROJECT_DIR/.claude/skills/_index.md" ]]; then
        grep '^- ' "$PROJECT_DIR/.claude/skills/_index.md" 2>/dev/null | head -30 || echo "[No skills found]"
    else
        echo "[Skill index not found]"
    fi
    echo ""
    echo ""

    # ── Active Tasks ──
    echo "## Active Tasks"
    echo ""
    safe_cat "$PROJECT_DIR/.claude/context/.active-tasks.txt" "No active tasks."
    echo ""
    echo ""

    # ── Recent Chat History (last 40% — RTK-style truncation) ──
    echo "## Recent Chat History (Last 40%)"
    echo ""
    LATEST_EXPORT=$(ls -t "$PROJECT_DIR/.claude/exports/chat-"*"-pre-compress.txt" 2>/dev/null | head -1)
    if [[ -n "${LATEST_EXPORT:-}" ]] && [[ -f "$LATEST_EXPORT" ]]; then
        TOTAL_LINES=$(wc -l < "$LATEST_EXPORT" | tr -d ' ')
        if [[ "$TOTAL_LINES" -gt 0 ]]; then
            SKIP=$((TOTAL_LINES * 60 / 100))
            tail -n "+${SKIP}" "$LATEST_EXPORT"
        else
            echo "[Chat export empty]"
        fi
    else
        # Try context captures as fallback
        LATEST_CAPTURE=$(ls -t "$PROJECT_DIR/.claude/context/.context-captured"*.txt 2>/dev/null | head -1)
        if [[ -n "${LATEST_CAPTURE:-}" ]] && [[ -f "$LATEST_CAPTURE" ]]; then
            TOTAL_LINES=$(wc -l < "$LATEST_CAPTURE" | tr -d ' ')
            SKIP=$((TOTAL_LINES * 60 / 100))
            tail -n "+${SKIP}" "$LATEST_CAPTURE"
        else
            echo "[No chat export or context capture found]"
        fi
    fi
    echo ""
    echo ""

    # ── Session State ──
    echo "## Session State"
    echo ""
    safe_cat "$PROJECT_DIR/.claude/context/session-state.md" "[Session state not found]"
    echo ""
    echo ""

    # ── Current Priorities ──
    echo "## Current Priorities"
    echo ""
    safe_cat "$PROJECT_DIR/.claude/context/current-priorities.md" "[Current priorities not found]"
    echo ""

} | collapse_blank_lines > "$TMP_FILE"

# ─── Size Cap (RTK-style hard limit) ──────────────────────────────────────
ACTUAL_CHARS=$(wc -c < "$TMP_FILE" | tr -d ' ')
if [[ "$ACTUAL_CHARS" -gt "$MAX_CHARS" ]]; then
    log "Size cap: ${ACTUAL_CHARS} chars exceeds ${MAX_CHARS} — truncating"
    head -c "$MAX_CHARS" "$TMP_FILE" > "$OUTPUT_FILE"
    # Ensure we end cleanly (don't cut mid-line)
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "[TRUNCATED at ${MAX_CHARS} chars — original was ${ACTUAL_CHARS} chars]" >> "$OUTPUT_FILE"
else
    mv "$TMP_FILE" "$OUTPUT_FILE"
fi
rm -f "$TMP_FILE"

FINAL_CHARS=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
FINAL_LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
log "Done: ${FINAL_LINES} lines, ${FINAL_CHARS} chars (~$((FINAL_CHARS / 4)) tokens)"
log "Output: $OUTPUT_FILE"

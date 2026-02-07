#!/bin/bash
#
# Weekly Context Analysis
#
# Analyzes Claude Code context usage patterns and suggests optimizations.
# Designed to run weekly via cron.
#
# Features:
# - Session statistics from tool usage logs
# - File size analysis (CLAUDE.md, context/ files)
# - Git churn analysis (frequently modified files)
# - Auto-archive old logs (delete after 365 days)
# - AUTO-REDUCE large context files using Ollama (optional)
# - Memory graph placeholder (requires interactive session)
#
# Output: Markdown report in .claude/logs/reports/
#
# Configuration: Copy config.sh.template to config.sh and customize.
#
# Recommended Ollama Models (in order of quality):
#   1. llama3.1:8b        - Best instruction following, recommended
#   2. mistral:7b-instruct - Fast and reliable
#   3. qwen2.5:7b-instruct - Good but can be slow
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration if available
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Defaults (can be overridden by config.sh or environment)
PROJECT_DIR="${JARVIS_DIR:-$HOME/Claude/Jarvis}"
CONTEXT_LOGS="$PROJECT_DIR/.claude/logs/context-usage"
SESSION_LOGS="$PROJECT_DIR/.claude/logs"
REPORT_DIR="$PROJECT_DIR/.claude/logs/reports"
ARCHIVE_DIR="$PROJECT_DIR/.claude/logs/archive"
BACKUP_DIR="$PROJECT_DIR/.claude/logs/backups"
REPORT_FILE="$REPORT_DIR/context-analysis-$(date +%Y-%m-%d).md"

# Configuration with defaults
# Note: Ollama integration disabled by default - set CONTEXT_REDUCE=true to enable
CONTEXT_REDUCE="${CONTEXT_REDUCE:-false}"
REDUCE_THRESHOLD="${REDUCE_THRESHOLD:-5000}"
REDUCE_MAX_SIZE="${REDUCE_MAX_SIZE:-50000}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_TIMEOUT="${OLLAMA_TIMEOUT:-120}"

# Test mode: just test Ollama connection and summarization
if [ "${1:-}" = "--test" ]; then
  echo "Testing Ollama connection and summarization..."
  echo "Model: $OLLAMA_MODEL"
  echo "Host: $OLLAMA_HOST"
  echo ""

  # Test connection
  if curl -s --max-time 5 "$OLLAMA_HOST/api/tags" >/dev/null 2>&1; then
    echo "✓ Ollama API responding"
  else
    echo "✗ Ollama API not responding"
    exit 1
  fi

  # Test model availability
  if curl -s "$OLLAMA_HOST/api/tags" | jq -e ".models[] | select(.name==\"$OLLAMA_MODEL\")" >/dev/null 2>&1; then
    echo "✓ Model $OLLAMA_MODEL available"
  else
    echo "✗ Model $OLLAMA_MODEL not found. Install with: ollama pull $OLLAMA_MODEL"
    exit 1
  fi

  # Test generation
  echo "Testing generation (10 second timeout)..."
  RESPONSE=$(curl -s --max-time 10 "$OLLAMA_HOST/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"$OLLAMA_MODEL\", \"prompt\": \"Say hello in exactly 3 words.\", \"stream\": false}" 2>&1)

  if echo "$RESPONSE" | jq -e '.response' >/dev/null 2>&1; then
    ANSWER=$(echo "$RESPONSE" | jq -r '.response')
    echo "✓ Generation working: \"$ANSWER\""
    echo ""
    echo "All tests passed! Ready for context reduction."
  else
    echo "✗ Generation failed: $RESPONSE"
    exit 1
  fi
  exit 0
fi

# Ensure directories exist
mkdir -p "$REPORT_DIR" "$ARCHIVE_DIR" "$BACKUP_DIR"

echo "# Weekly Context Analysis Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "**Project**: $PROJECT_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================================================
# 1. SESSION STATISTICS
# ============================================================================

echo "## Session Statistics" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Jarvis uses multiple log sources instead of single audit.jsonl
SELECTION_LOG="$SESSION_LOGS/selection-audit.jsonl"
SESSION_EVENTS_LOG="$SESSION_LOGS/session-events.jsonl"
TELEMETRY_DIR="$SESSION_LOGS/telemetry"

# Count log entries from all sources
TOTAL_ENTRIES=0
echo "### Log Sources" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Source | Entries | Size |" >> "$REPORT_FILE"
echo "|--------|---------|------|" >> "$REPORT_FILE"

if [[ -f "$SELECTION_LOG" ]]; then
    ENTRIES=$(wc -l < "$SELECTION_LOG" | tr -d ' ')
    SIZE=$(du -h "$SELECTION_LOG" 2>/dev/null | cut -f1 || echo "0")
    echo "| selection-audit.jsonl | $ENTRIES | $SIZE |" >> "$REPORT_FILE"
    ((TOTAL_ENTRIES += ENTRIES)) || true
fi

if [[ -f "$SESSION_EVENTS_LOG" ]]; then
    ENTRIES=$(wc -l < "$SESSION_EVENTS_LOG" | tr -d ' ')
    SIZE=$(du -h "$SESSION_EVENTS_LOG" 2>/dev/null | cut -f1 || echo "0")
    echo "| session-events.jsonl | $ENTRIES | $SIZE |" >> "$REPORT_FILE"
    ((TOTAL_ENTRIES += ENTRIES)) || true
fi

if [[ -d "$TELEMETRY_DIR" ]]; then
    TELEMETRY_FILES=$(find "$TELEMETRY_DIR" -name "events-*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$TELEMETRY_FILES" -gt 0 ]]; then
        ENTRIES=$(cat "$TELEMETRY_DIR"/events-*.jsonl 2>/dev/null | wc -l | tr -d ' ')
        SIZE=$(du -sh "$TELEMETRY_DIR" 2>/dev/null | cut -f1 || echo "0")
        echo "| telemetry/ ($TELEMETRY_FILES files) | $ENTRIES | $SIZE |" >> "$REPORT_FILE"
        ((TOTAL_ENTRIES += ENTRIES)) || true
    fi
fi

if [[ $TOTAL_ENTRIES -eq 0 ]]; then
    echo "| *No logs found* | - | - |" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "- **Total log entries**: $TOTAL_ENTRIES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Tool usage breakdown from selection-audit.jsonl
if [[ -f "$SELECTION_LOG" ]] && command -v jq &>/dev/null; then
    echo "### Tool/Agent Usage (Top 10)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| Type | Name | Calls |" >> "$REPORT_FILE"
    echo "|------|------|-------|" >> "$REPORT_FILE"

    jq -s 'group_by(.type + ":" + (.tool // .agent // .skill // "unknown"))
        | map({key: .[0].type, name: (.[0].tool // .[0].agent // .[0].skill // "unknown"), count: length})
        | sort_by(-.count)
        | .[0:10]
        | .[]
        | "| \(.key) | \(.name) | \(.count) |"' "$SELECTION_LOG" 2>/dev/null >> "$REPORT_FILE" || echo "*Could not parse tool usage*" >> "$REPORT_FILE"

    echo "" >> "$REPORT_FILE"
fi

# ============================================================================
# 2. FILE SIZE ANALYSIS
# ============================================================================

echo "## Context File Sizes" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# CLAUDE.md size
# Check root CLAUDE.md first (canonical), fall back to .claude/CLAUDE.md
CLAUDE_MD_PATH=""
if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
    CLAUDE_MD_PATH="$PROJECT_DIR/CLAUDE.md"
elif [[ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]]; then
    CLAUDE_MD_PATH="$PROJECT_DIR/.claude/CLAUDE.md"
fi
if [[ -n "$CLAUDE_MD_PATH" ]]; then
    CLAUDE_SIZE=$(wc -c < "$CLAUDE_MD_PATH" | tr -d ' ')
    CLAUDE_TOKENS=$((CLAUDE_SIZE / 4))
    echo "- **CLAUDE.md**: $CLAUDE_SIZE bytes (~$CLAUDE_TOKENS tokens)" >> "$REPORT_FILE"
fi

# Context directory total
if [[ -d "$PROJECT_DIR/.claude/context" ]]; then
    CONTEXT_SIZE=$(du -sb "$PROJECT_DIR/.claude/context" 2>/dev/null | cut -f1 || echo "0")
    CONTEXT_TOKENS=$((CONTEXT_SIZE / 4))
    echo "- **context/ directory**: $CONTEXT_SIZE bytes (~$CONTEXT_TOKENS tokens)" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Top 10 largest context files
echo "### Largest Context Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Bytes | ~Tokens |" >> "$REPORT_FILE"
echo "|------|-------|---------|" >> "$REPORT_FILE"

if [[ -d "$PROJECT_DIR/.claude/context" ]]; then
    find "$PROJECT_DIR/.claude/context" -name "*.md" -type f -exec wc -c {} \; 2>/dev/null \
        | sort -rn \
        | head -10 \
        | while read -r size filepath; do
            relpath="${filepath#$PROJECT_DIR/}"
            tokens=$((size / 4))
            echo "| \`$relpath\` | $size | ~$tokens |"
        done >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# 3. GIT CHURN ANALYSIS
# ============================================================================

echo "## Git Churn Analysis (Last 30 Days)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [[ -d "$PROJECT_DIR/.git" ]]; then
    echo "### Most Frequently Modified Context Files" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| File | Commits |" >> "$REPORT_FILE"
    echo "|------|---------|" >> "$REPORT_FILE"

    # Get files with most commits in last 30 days
    cd "$PROJECT_DIR"
    git log --since="30 days ago" --name-only --pretty=format: -- ".claude/context/*.md" 2>/dev/null \
        | grep -v '^$' \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | while read -r count filepath; do
            echo "| \`$filepath\` | $count |"
        done >> "$REPORT_FILE"

    echo "" >> "$REPORT_FILE"

    # Check for rapidly growing files
    echo "### Files with Significant Growth" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    GROWING_FILES=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            CURRENT_SIZE=$(wc -c < "$file" | tr -d ' ')
            # Get size from 30 days ago
            OLD_CONTENT=$(git show "HEAD~30:$file" 2>/dev/null || echo "")
            if [[ -n "$OLD_CONTENT" ]]; then
                OLD_SIZE=${#OLD_CONTENT}
                if [[ $OLD_SIZE -gt 0 ]]; then
                    GROWTH=$(( (CURRENT_SIZE - OLD_SIZE) * 100 / OLD_SIZE ))
                    if [[ $GROWTH -gt 20 ]]; then
                        echo "- \`$file\`: +${GROWTH}% ($OLD_SIZE → $CURRENT_SIZE bytes)" >> "$REPORT_FILE"
                        ((GROWING_FILES++))
                    fi
                fi
            fi
        fi
    done < <(find ".claude/context" -name "*.md" -type f 2>/dev/null)

    if [[ $GROWING_FILES -eq 0 ]]; then
        echo "*No files grew more than 20% in the last 30 days.*" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
else
    echo "*Not a git repository - skipping churn analysis*" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# ============================================================================
# 4. AUTO-ARCHIVE OLD LOGS
# ============================================================================

echo "## Log Archive Status" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Archive logs older than 30 days
ARCHIVED_COUNT=0
if [[ -d "$SESSION_LOGS" ]]; then
    while IFS= read -r logfile; do
        if [[ -f "$logfile" ]]; then
            mv "$logfile" "$ARCHIVE_DIR/"
            ((ARCHIVED_COUNT++))
        fi
    done < <(find "$SESSION_LOGS" -maxdepth 1 -name "*.log" -mtime +30 2>/dev/null)
fi

if [[ $ARCHIVED_COUNT -gt 0 ]]; then
    echo "- **Archived**: $ARCHIVED_COUNT log files (>30 days old)" >> "$REPORT_FILE"
else
    echo "- **Archived**: No logs needed archiving" >> "$REPORT_FILE"
fi

# Delete archives older than 365 days
DELETED_COUNT=0
if [[ -d "$ARCHIVE_DIR" ]]; then
    while IFS= read -r oldfile; do
        rm -f "$oldfile"
        ((DELETED_COUNT++))
    done < <(find "$ARCHIVE_DIR" -type f -mtime +365 2>/dev/null)
fi

if [[ $DELETED_COUNT -gt 0 ]]; then
    echo "- **Deleted**: $DELETED_COUNT archive files (>365 days old)" >> "$REPORT_FILE"
fi

# Archive size
if [[ -d "$ARCHIVE_DIR" ]]; then
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "0")
    ARCHIVE_FILES=$(find "$ARCHIVE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "- **Archive**: $ARCHIVE_FILES files, $ARCHIVE_SIZE total" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# 5. CONTEXT REDUCTION (OLLAMA)
# ============================================================================

echo "## Context Reduction" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [[ "$CONTEXT_REDUCE" == "true" ]]; then
    echo "**Mode**: Automatic reduction enabled (Ollama: $OLLAMA_MODEL)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Check Ollama availability
    if ! curl -s --max-time 5 "$OLLAMA_HOST/api/tags" >/dev/null 2>&1; then
        echo "⚠️ **Ollama not available** - skipping reduction" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        # Find large context files
        REDUCED_COUNT=0
        REDUCED_BYTES=0
        SKIPPED_LARGE=0

        echo "### Reduction Results" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

        while IFS= read -r filepath; do
            SIZE=$(wc -c < "$filepath" | tr -d ' ')
            TOKENS=$((SIZE / 4))

            # Skip if too small
            [[ $TOKENS -lt $REDUCE_THRESHOLD ]] && continue

            # Skip if too large (would timeout)
            if [[ $TOKENS -gt $REDUCE_MAX_SIZE ]]; then
                ((SKIPPED_LARGE++))
                continue
            fi

            RELPATH="${filepath#$PROJECT_DIR/}"
            echo "Processing: $RELPATH ($TOKENS tokens)..."

            # Create backup
            cp "$filepath" "$BACKUP_DIR/$(basename "$filepath").$(date +%Y%m%d%H%M%S).bak"

            # Read content
            CONTENT=$(cat "$filepath")

            # Create prompt for summarization
            PROMPT="You are a technical documentation summarizer. Summarize the following markdown documentation while:
1. Preserving all essential technical details, commands, and configurations
2. Keeping all code blocks intact
3. Maintaining the document structure (headers, lists)
4. Removing redundant explanations and verbose prose
5. Keeping the summary at least 40% shorter than the original

Original document:

$CONTENT

Provide only the summarized markdown, no explanations:"

            # Call Ollama
            RESPONSE=$(curl -s --max-time "$OLLAMA_TIMEOUT" "$OLLAMA_HOST/api/generate" \
                -H "Content-Type: application/json" \
                -d "$(jq -n --arg model "$OLLAMA_MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false}')" 2>&1)

            SUMMARY=$(echo "$RESPONSE" | jq -r '.response // empty' 2>/dev/null)

            if [[ -n "$SUMMARY" ]]; then
                NEW_SIZE=${#SUMMARY}
                if [[ $NEW_SIZE -lt $SIZE ]]; then
                    echo "$SUMMARY" > "$filepath"
                    SAVED=$((SIZE - NEW_SIZE))
                    ((REDUCED_BYTES += SAVED))
                    ((REDUCED_COUNT++))
                    echo "- \`$RELPATH\`: $SIZE → $NEW_SIZE bytes (-$SAVED)" >> "$REPORT_FILE"
                else
                    echo "- \`$RELPATH\`: No reduction (summary larger)" >> "$REPORT_FILE"
                    # Restore from backup
                    cp "$BACKUP_DIR/$(basename "$filepath")."*.bak "$filepath" 2>/dev/null || true
                fi
            else
                echo "- \`$RELPATH\`: Failed to summarize" >> "$REPORT_FILE"
            fi

        done < <(find "$PROJECT_DIR/.claude/context" -name "*.md" -type f 2>/dev/null)

        echo "" >> "$REPORT_FILE"
        if [[ $SKIPPED_LARGE -gt 0 ]]; then
            echo "*Skipped $SKIPPED_LARGE files exceeding ${REDUCE_MAX_SIZE} token limit*" >> "$REPORT_FILE"
        fi

        if [[ $REDUCED_COUNT -gt 0 ]]; then
            echo "" >> "$REPORT_FILE"
            echo "**Total reduced**: $REDUCED_COUNT files, ~$((REDUCED_BYTES / 4)) tokens saved" >> "$REPORT_FILE"
        fi
    fi
else
    echo "**Mode**: Manual (set CONTEXT_REDUCE=true to enable)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Just report large files
    LARGE_FILES=$(find "$PROJECT_DIR/.claude/context" -name "*.md" -type f -exec wc -c {} \; 2>/dev/null \
        | awk -v threshold="$((REDUCE_THRESHOLD * 4))" '$1 > threshold {print}' \
        | wc -l | tr -d ' ')

    if [[ $LARGE_FILES -gt 0 ]]; then
        echo "**$LARGE_FILES files exceed $REDUCE_THRESHOLD token threshold** - consider manual review" >> "$REPORT_FILE"
    else
        echo "*No files exceed the $REDUCE_THRESHOLD token threshold.*" >> "$REPORT_FILE"
    fi
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# 6. MEMORY GRAPH (PLACEHOLDER)
# ============================================================================

echo "## Memory Graph Status" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "*Memory graph analysis requires an interactive Claude session.*" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Run \`/memory-review\` in a Claude Code session to:" >> "$REPORT_FILE"
echo "- View entity and relation counts" >> "$REPORT_FILE"
echo "- Identify orphaned nodes" >> "$REPORT_FILE"
echo "- Find duplicate entities" >> "$REPORT_FILE"
echo "- Get cleanup recommendations" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================================================
# 7. RECOMMENDATIONS
# ============================================================================

echo "## Recommendations" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

RECOMMENDATIONS=0

# Check CLAUDE.md size
# Check root CLAUDE.md first (canonical), fall back to .claude/CLAUDE.md
CLAUDE_MD_CHECK=""
if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
    CLAUDE_MD_CHECK="$PROJECT_DIR/CLAUDE.md"
elif [[ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]]; then
    CLAUDE_MD_CHECK="$PROJECT_DIR/.claude/CLAUDE.md"
fi
if [[ -n "$CLAUDE_MD_CHECK" ]]; then
    CLAUDE_TOKENS=$(($(wc -c < "$CLAUDE_MD_CHECK" | tr -d ' ') / 4))
    if [[ $CLAUDE_TOKENS -gt 3000 ]]; then
        echo "- [ ] **CLAUDE.md is large** (~$CLAUDE_TOKENS tokens). Consider moving detailed docs to knowledge/ and linking." >> "$REPORT_FILE"
        ((RECOMMENDATIONS++))
    fi
fi

# Check for stale context files (not modified in 90+ days)
STALE_FILES=$(find "$PROJECT_DIR/.claude/context" -name "*.md" -mtime +90 2>/dev/null | wc -l | tr -d ' ')
if [[ $STALE_FILES -gt 0 ]]; then
    echo "- [ ] **$STALE_FILES stale context files** (not modified in 90+ days). Review for archiving." >> "$REPORT_FILE"
    ((RECOMMENDATIONS++))
fi

# Check audit log size
if [[ -f "$AUDIT_LOG" ]]; then
    AUDIT_SIZE=$(wc -c < "$AUDIT_LOG" | tr -d ' ')
    if [[ $AUDIT_SIZE -gt 10485760 ]]; then  # 10MB
        echo "- [ ] **Audit log is large** ($(du -h "$AUDIT_LOG" | cut -f1)). Consider rotation." >> "$REPORT_FILE"
        ((RECOMMENDATIONS++))
    fi
fi

if [[ $RECOMMENDATIONS -eq 0 ]]; then
    echo "✓ No immediate actions recommended." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# DONE
# ============================================================================

echo "---" >> "$REPORT_FILE"
echo "*Report generated by weekly-context-analysis.sh*" >> "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"

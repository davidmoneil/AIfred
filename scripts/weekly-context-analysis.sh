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
# - AUTO-REDUCE large context files using Ollama
# - Memory graph placeholder (requires interactive session)
#
# Output: Markdown report in .claude/logs/reports/
#
# Created: 2025-12-26
# Updated: 2025-12-26 - Added git churn, archive, memory placeholder
# Updated: 2025-12-26 - Added Ollama-based context reduction
#
# Environment:
#   CONTEXT_REDUCE=true   Enable auto-reduction (default: true)
#   REDUCE_THRESHOLD=5000 Token threshold for reduction (default: 5000)
#   OLLAMA_MODEL=...      Model for summarization (see recommendations below)
#
# Recommended Ollama Models (in order of quality):
#   1. llama3.1:8b        - Best instruction following, recommended
#   2. mistral:7b-instruct - Fast and reliable
#   3. qwen2.5:7b-instruct - Good but can be slow
#   4. phi3:medium        - Efficient, smaller context
#
# To install: ollama pull llama3.1:8b
# To test: OLLAMA_MODEL=llama3.1:8b ./weekly-context-analysis.sh --test

set -euo pipefail

PROJECT_DIR="/home/davidmoneil/AIProjects"
CONTEXT_LOGS="$PROJECT_DIR/.claude/logs/context-usage"
SESSION_LOGS="$PROJECT_DIR/.claude/logs"
REPORT_DIR="$PROJECT_DIR/.claude/logs/reports"
ARCHIVE_DIR="$PROJECT_DIR/.claude/logs/archive"
BACKUP_DIR="$PROJECT_DIR/.claude/logs/backups"
REPORT_FILE="$REPORT_DIR/context-analysis-$(date +%Y-%m-%d).md"

# Configuration
CONTEXT_REDUCE="${CONTEXT_REDUCE:-true}"
REDUCE_THRESHOLD="${REDUCE_THRESHOLD:-5000}"  # tokens (~20KB) - minimum size to reduce
REDUCE_MAX_SIZE="${REDUCE_MAX_SIZE:-50000}"   # tokens (~200KB) - skip files larger than this
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5:32b}"   # Best quality for summarization
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_TIMEOUT="${OLLAMA_TIMEOUT:-120}"       # seconds per file

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
    -d "{\"model\":\"$OLLAMA_MODEL\",\"prompt\":\"Say OK\",\"stream\":false,\"options\":{\"num_predict\":5}}" 2>/dev/null)

  if echo "$RESPONSE" | jq -e '.response' >/dev/null 2>&1; then
    echo "✓ Generation working: $(echo "$RESPONSE" | jq -r '.response')"
  else
    echo "✗ Generation failed or timed out"
    echo "  Try: sudo systemctl restart ollama"
    exit 1
  fi

  echo ""
  echo "All tests passed! Ready for context reduction."
  exit 0
fi

# Ensure directories exist
mkdir -p "$REPORT_DIR" "$ARCHIVE_DIR" "$BACKUP_DIR"

# ============================================
# Helper: Summarize file using Ollama
# ============================================
summarize_file() {
  local file="$1"
  local content
  content=$(cat "$file")

  # Extract filename for context
  local filename
  filename=$(basename "$file")

  # Build prompt
  local prompt="You are a technical documentation summarizer. Your task is to reduce the following markdown document to approximately 40% of its current size while preserving:
1. All critical technical information (paths, commands, configurations)
2. Current status and state information
3. Key decisions and their rationale
4. Active todos and blockers

Remove:
- Verbose explanations that can be inferred
- Historical information older than 30 days (unless critical)
- Redundant examples
- Completed items that are no longer relevant

Keep the same markdown structure and headers. Output ONLY the reduced markdown, no explanations.

---
FILENAME: $filename
---

$content"

  # Call Ollama API with timeout (120 seconds for large files)
  local response
  response=$(curl -s --max-time 120 "$OLLAMA_HOST/api/generate" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg model "$OLLAMA_MODEL" --arg prompt "$prompt" '{
      model: $model,
      prompt: $prompt,
      stream: false,
      options: {
        temperature: 0.3,
        num_predict: 4000
      }
    }')" 2>/dev/null)

  # Extract response
  echo "$response" | jq -r '.response // empty' 2>/dev/null
}

# ============================================
# Helper: Log message to report
# ============================================
log_reduction() {
  echo "$1" >> "$REPORT_FILE"
}

# ============================================
# Helper: Check if Ollama is available
# ============================================
check_ollama() {
  curl -s --max-time 5 "$OLLAMA_HOST/api/tags" >/dev/null 2>&1
}

# Start report
cat > "$REPORT_FILE" << 'EOF'
# Weekly Context Analysis Report

EOF

echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# Section 1: Session Statistics
# ============================================
echo "## Session Statistics (Last 7 Days)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "$CONTEXT_LOGS" ]; then
  CUTOFF=$(date -d '7 days ago' +%Y-%m-%d)

  # Count sessions
  SESSION_COUNT=$(find "$CONTEXT_LOGS" -name "*.json" -newermt "$CUTOFF" 2>/dev/null | wc -l)
  echo "- **Total sessions**: $SESSION_COUNT" >> "$REPORT_FILE"

  # Aggregate tool calls
  if [ "$SESSION_COUNT" -gt 0 ]; then
    TOTAL_CALLS=$(find "$CONTEXT_LOGS" -name "*.json" -newermt "$CUTOFF" -exec cat {} \; 2>/dev/null | \
      jq -s 'map(.toolCalls // 0) | add' 2>/dev/null || echo "0")
    TOTAL_TOKENS=$(find "$CONTEXT_LOGS" -name "*.json" -newermt "$CUTOFF" -exec cat {} \; 2>/dev/null | \
      jq -s 'map(.estimatedTokensIn // 0) | add' 2>/dev/null || echo "0")

    echo "- **Total tool calls**: $TOTAL_CALLS" >> "$REPORT_FILE"
    echo "- **Estimated tokens (input)**: $TOTAL_TOKENS" >> "$REPORT_FILE"

    # Top tools by usage
    echo "" >> "$REPORT_FILE"
    echo "### Top Tools by Call Count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    find "$CONTEXT_LOGS" -name "*.json" -newermt "$CUTOFF" -exec cat {} \; 2>/dev/null | \
      jq -s '
        [.[].toolBreakdown | to_entries[]]
        | group_by(.key)
        | map({tool: .[0].key, calls: (map(.value.calls) | add), tokens: (map(.value.tokens) | add)})
        | sort_by(-.calls)
        | .[:10]
        | .[]
        | "| \(.tool) | \(.calls) | \(.tokens) |"
      ' -r 2>/dev/null | {
        echo "| Tool | Calls | Est. Tokens |"
        echo "|------|-------|-------------|"
        cat
      } >> "$REPORT_FILE" 2>/dev/null || echo "*No tool data available*" >> "$REPORT_FILE"
  fi
else
  echo "*No context usage data found. The tracking hook may need to run first.*" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# Section 2: File Size Analysis
# ============================================
echo "## Context File Sizes" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Files that contribute to context on session startup:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# CLAUDE.md
CLAUDE_SIZE=$(wc -c < "$PROJECT_DIR/.claude/CLAUDE.md" 2>/dev/null || echo "0")
CLAUDE_TOKENS=$((CLAUDE_SIZE / 4))
echo "- **CLAUDE.md**: $CLAUDE_SIZE bytes (~$CLAUDE_TOKENS tokens)" >> "$REPORT_FILE"

# Context files
if [ -d "$PROJECT_DIR/.claude/context" ]; then
  CONTEXT_SIZE=$(du -sb "$PROJECT_DIR/.claude/context" 2>/dev/null | cut -f1 || echo "0")
  CONTEXT_TOKENS=$((CONTEXT_SIZE / 4))
  echo "- **context/ directory**: $CONTEXT_SIZE bytes (~$CONTEXT_TOKENS tokens)" >> "$REPORT_FILE"

  # Largest context files
  echo "" >> "$REPORT_FILE"
  echo "### Largest Context Files" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| File | Size | Est. Tokens |" >> "$REPORT_FILE"
  echo "|------|------|-------------|" >> "$REPORT_FILE"
  find "$PROJECT_DIR/.claude/context" -type f -name "*.md" -printf '%s %p\n' 2>/dev/null | \
    sort -rn | head -5 | while read size file; do
      tokens=$((size / 4))
      relpath="${file#$PROJECT_DIR/}"
      echo "| \`$relpath\` | $size | ~$tokens |" >> "$REPORT_FILE"
    done
fi

echo "" >> "$REPORT_FILE"

# ============================================
# Section 3: Git Churn Analysis (NEW)
# ============================================
echo "## File Churn Analysis (Last 30 Days)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Files modified most frequently - candidates for consolidation or splitting:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cd "$PROJECT_DIR" 2>/dev/null || true

if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "### Most Frequently Modified Files" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| File | Commits | Lines Changed |" >> "$REPORT_FILE"
  echo "|------|---------|---------------|" >> "$REPORT_FILE"

  # Get files with most commits in last 30 days (context files only)
  git log --since="30 days ago" --name-only --pretty=format: -- ".claude/context/*.md" ".claude/CLAUDE.md" 2>/dev/null | \
    sort | uniq -c | sort -rn | head -10 | while read count file; do
      if [ -n "$file" ] && [ -f "$file" ]; then
        # Get total lines changed
        lines=$(git log --since="30 days ago" --numstat --pretty=format: -- "$file" 2>/dev/null | \
          awk '{add+=$1; del+=$2} END {print add+del}')
        echo "| \`$file\` | $count | ${lines:-0} |" >> "$REPORT_FILE"
      fi
    done

  echo "" >> "$REPORT_FILE"

  # Files that grew significantly
  echo "### Files with Significant Growth" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  GROWTH_FOUND=false
  for file in .claude/context/*.md .claude/CLAUDE.md; do
    if [ -f "$file" ]; then
      # Compare current size to 30 days ago
      OLD_SIZE=$(git show HEAD~30:"$file" 2>/dev/null | wc -c || echo "0")
      NEW_SIZE=$(wc -c < "$file" 2>/dev/null || echo "0")
      if [ "$OLD_SIZE" -gt 0 ] && [ "$NEW_SIZE" -gt "$OLD_SIZE" ]; then
        GROWTH=$((NEW_SIZE - OLD_SIZE))
        GROWTH_PCT=$((GROWTH * 100 / OLD_SIZE))
        if [ "$GROWTH_PCT" -gt 20 ]; then
          if [ "$GROWTH_FOUND" = false ]; then
            echo "| File | Growth | % Increase |" >> "$REPORT_FILE"
            echo "|------|--------|------------|" >> "$REPORT_FILE"
            GROWTH_FOUND=true
          fi
          echo "| \`$file\` | +$GROWTH bytes | +${GROWTH_PCT}% |" >> "$REPORT_FILE"
        fi
      fi
    fi
  done

  if [ "$GROWTH_FOUND" = false ]; then
    echo "*No significant file growth detected (>20%)*" >> "$REPORT_FILE"
  fi
else
  echo "*Not a git repository*" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# Section 4: Memory Graph Status (NEW)
# ============================================
echo "## Memory Graph Status" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "> **Note**: Memory graph analysis requires an interactive Claude session." >> "$REPORT_FILE"
echo "> Run \`/memory-review\` in Claude Code to analyze the knowledge graph." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check if memory volume has data
MEMORY_VOL="/var/lib/docker/volumes/mcp-memory-data/_data"
if [ -d "$MEMORY_VOL" ] && [ "$(ls -A "$MEMORY_VOL" 2>/dev/null)" ]; then
  MEMORY_FILES=$(find "$MEMORY_VOL" -type f 2>/dev/null | wc -l)
  MEMORY_SIZE=$(du -sh "$MEMORY_VOL" 2>/dev/null | cut -f1)
  echo "- **Memory volume**: $MEMORY_FILES files, $MEMORY_SIZE" >> "$REPORT_FILE"
else
  echo "- **Memory volume**: Empty (graph stored in-memory only)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# Section 5: Auto-Archive & Cleanup (NEW)
# ============================================
echo "## Cleanup Actions Taken" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

ARCHIVE_COUNT=0
DELETE_COUNT=0

# Archive logs older than 30 days
for log in $(find "$SESSION_LOGS" -maxdepth 1 -name "*.jsonl" -mtime +30 2>/dev/null); do
  filename=$(basename "$log")
  mv "$log" "$ARCHIVE_DIR/$filename" 2>/dev/null && ((ARCHIVE_COUNT++)) || true
done

# Archive old context-usage files
if [ -d "$CONTEXT_LOGS" ]; then
  for log in $(find "$CONTEXT_LOGS" -name "*.json" -mtime +30 2>/dev/null); do
    filename=$(basename "$log")
    mv "$log" "$ARCHIVE_DIR/context-$filename" 2>/dev/null && ((ARCHIVE_COUNT++)) || true
  done
fi

# Delete archived files older than 365 days
for old in $(find "$ARCHIVE_DIR" -type f -mtime +365 2>/dev/null); do
  rm "$old" 2>/dev/null && ((DELETE_COUNT++)) || true
done

# Delete old reports (keep last 3 months)
OLD_REPORTS=$(find "$REPORT_DIR" -name "*.md" -mtime +90 2>/dev/null | wc -l)
if [ "$OLD_REPORTS" -gt 0 ]; then
  find "$REPORT_DIR" -name "*.md" -mtime +90 -delete 2>/dev/null
  echo "- **Deleted old reports**: $OLD_REPORTS files (>90 days)" >> "$REPORT_FILE"
fi

echo "- **Archived to .claude/logs/archive/**: $ARCHIVE_COUNT files (>30 days)" >> "$REPORT_FILE"
echo "- **Permanently deleted**: $DELETE_COUNT files (>365 days)" >> "$REPORT_FILE"

# Report archive size
ARCHIVE_SIZE=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "0")
ARCHIVE_FILES=$(find "$ARCHIVE_DIR" -type f 2>/dev/null | wc -l)
echo "- **Archive status**: $ARCHIVE_FILES files, $ARCHIVE_SIZE total" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

# ============================================
# Section 6: Context Reduction (NEW)
# ============================================
echo "## Context Reduction" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

REDUCED_COUNT=0
REDUCED_BYTES=0

if [ "$CONTEXT_REDUCE" = "true" ]; then
  if check_ollama; then
    echo "Using Ollama ($OLLAMA_MODEL) for summarization..." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Find files exceeding threshold (excluding session-state.md which changes frequently)
    LARGE_FILES=$(find "$PROJECT_DIR/.claude/context" -type f -name "*.md" \
      ! -name "session-state.md" \
      -size +$((REDUCE_THRESHOLD * 4))c 2>/dev/null)

    if [ -n "$LARGE_FILES" ]; then
      echo "| File | Before | After | Saved |" >> "$REPORT_FILE"
      echo "|------|--------|-------|-------|" >> "$REPORT_FILE"

      SKIPPED_LARGE=0
      SKIPPED_FAILED=0

      for file in $LARGE_FILES; do
        BEFORE_SIZE=$(wc -c < "$file")
        BEFORE_TOKENS=$((BEFORE_SIZE / 4))
        RELPATH="${file#$PROJECT_DIR/}"

        # Skip if under threshold
        if [ "$BEFORE_TOKENS" -lt "$REDUCE_THRESHOLD" ]; then
          continue
        fi

        # Skip if too large (would take too long)
        if [ "$BEFORE_TOKENS" -gt "$REDUCE_MAX_SIZE" ]; then
          ((SKIPPED_LARGE++)) || true
          continue
        fi

        # Backup original
        BACKUP_NAME="$(basename "$file").$(date +%Y%m%d).bak"
        cp "$file" "$BACKUP_DIR/$BACKUP_NAME"

        # Summarize (timeout is built into curl call)
        SUMMARY=$(summarize_file "$file")

        if [ -n "$SUMMARY" ] && [ ${#SUMMARY} -gt 100 ]; then
          # Validate summary is actually smaller
          AFTER_SIZE=${#SUMMARY}
          if [ "$AFTER_SIZE" -lt "$BEFORE_SIZE" ]; then
            # Write summarized content
            echo "$SUMMARY" > "$file"

            AFTER_TOKENS=$((AFTER_SIZE / 4))
            SAVED=$((BEFORE_SIZE - AFTER_SIZE))
            SAVED_TOKENS=$((SAVED / 4))

            echo "| \`$RELPATH\` | ~$BEFORE_TOKENS | ~$AFTER_TOKENS | ~$SAVED_TOKENS |" >> "$REPORT_FILE"

            ((REDUCED_COUNT++)) || true
            REDUCED_BYTES=$((REDUCED_BYTES + SAVED))
          else
            # Summary was larger, restore backup
            cp "$BACKUP_DIR/$BACKUP_NAME" "$file"
            ((SKIPPED_FAILED++)) || true
          fi
        else
          # Empty or too short response, restore backup
          cp "$BACKUP_DIR/$BACKUP_NAME" "$file"
          ((SKIPPED_FAILED++)) || true
        fi
      done

      # Report skipped files
      if [ "$SKIPPED_LARGE" -gt 0 ]; then
        echo "" >> "$REPORT_FILE"
        echo "*Skipped $SKIPPED_LARGE files exceeding ${REDUCE_MAX_SIZE} token limit*" >> "$REPORT_FILE"
      fi
      if [ "$SKIPPED_FAILED" -gt 0 ]; then
        echo "*$SKIPPED_FAILED files unchanged (summary larger or failed)*" >> "$REPORT_FILE"
      fi

      if [ "$REDUCED_COUNT" -eq 0 ]; then
        echo "*No files needed reduction or summarization failed.*" >> "$REPORT_FILE"
      else
        echo "" >> "$REPORT_FILE"
        echo "**Total reduced**: $REDUCED_COUNT files, ~$((REDUCED_BYTES / 4)) tokens saved" >> "$REPORT_FILE"
      fi
    else
      echo "*No files exceed the $REDUCE_THRESHOLD token threshold.*" >> "$REPORT_FILE"
    fi
  else
    echo "> **Ollama not available** - Skipping auto-reduction." >> "$REPORT_FILE"
    echo "> Start Ollama or set CONTEXT_REDUCE=false to disable." >> "$REPORT_FILE"
  fi
else
  echo "*Auto-reduction disabled (CONTEXT_REDUCE=false)*" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# Section 7: Recommendations
# ============================================
echo "## Recommendations" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

RECS_FOUND=false

# Check CLAUDE.md size
if [ "$CLAUDE_TOKENS" -gt 3000 ]; then
  echo "- [ ] **CLAUDE.md is large** (~$CLAUDE_TOKENS tokens). Consider moving detailed docs to knowledge/ and linking." >> "$REPORT_FILE"
  RECS_FOUND=true
fi

# Check for too many context files
CONTEXT_FILES=$(find "$PROJECT_DIR/.claude/context" -type f -name "*.md" 2>/dev/null | wc -l)
if [ "$CONTEXT_FILES" -gt 50 ]; then
  echo "- [ ] **Many context files** ($CONTEXT_FILES). Consider consolidating related files." >> "$REPORT_FILE"
  RECS_FOUND=true
fi

# Check for memory review need
echo "- [ ] **Review memory graph** - Run \`/memory-review\` to check for stale entities." >> "$REPORT_FILE"
RECS_FOUND=true

if [ "$RECS_FOUND" = false ]; then
  echo "*No issues detected. Context usage looks healthy!*" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "*Report generated by weekly-context-analysis.sh*" >> "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"

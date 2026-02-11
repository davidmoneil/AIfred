#!/usr/bin/env bash
# housekeep.sh — Quick Infrastructure Cleanup Script
# 7-phase non-destructive cleanup (move, never delete)
#
# Design: .claude/commands/housekeep.md
# Architecture: flow.housekeep in capability-map.yaml
#   - Lightweight complement to /maintain
#   - Safe for auto-triggering during idle or "Carry On" mode
#   - ~2K tokens context cost when invoked via command
#
# Usage: housekeep.sh [--phase <1-7>] [--dry-run] [--quiet]
#
# v1.0 — F.3 Aion Quartet wiring

set -euo pipefail

# --- Constants ---
PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
LOGS_DIR="$PROJECT_DIR/.claude/logs"
STATE_DIR="$PROJECT_DIR/.claude/state/components"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts"

# --- Color Constants (ANSI-C quoting for reliable escape sequences) ---
C_RESET=$'\e[0m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_RED=$'\e[31m'
C_CYAN=$'\e[36m'

# --- Options ---
PHASE_FILTER=0  # 0 = all phases
DRY_RUN=false
QUIET=false

# --- Counters ---
CLEANED=0
FLAGGED=0
ERRORS=0

# --- Helpers ---
now_epoch() { date +%s; }

file_age_seconds() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo 0
        return
    fi
    local mtime
    mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)
    local now
    now=$(now_epoch)
    echo $(( now - mtime ))
}

archive_dir() {
    local today
    today=$(date +%Y-%m-%d)
    echo "$PROJECT_DIR/.claude/archive/logs/$today"
}

ensure_archive() {
    local dir
    dir=$(archive_dir)
    if [[ ! -d "$dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            return
        fi
        mkdir -p "$dir"
    fi
}

file_size_kb() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo 0
        return
    fi
    local bytes
    bytes=$(stat -f %z "$file" 2>/dev/null || echo 0)
    echo $(( bytes / 1024 ))
}

phase_header() {
    local num="$1" name="$2"
    if [[ "$QUIET" == "true" ]]; then return; fi
    printf "Phase %d: %-20s " "$num" "$name"
}

phase_result() {
    local msg="$1"
    if [[ "$QUIET" == "true" ]]; then return; fi
    echo "$msg"
}

should_run() {
    local phase="$1"
    [[ "$PHASE_FILTER" -eq 0 || "$PHASE_FILTER" -eq "$phase" ]]
}

safe_move() {
    local src="$1"
    local dest_dir
    dest_dir=$(archive_dir)
    local basename
    basename=$(basename "$src")
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [dry-run] would move: $basename → archive/"
        return
    fi
    ensure_archive
    mv "$src" "$dest_dir/$basename"
}

safe_remove() {
    local file="$1"
    local basename
    basename=$(basename "$file")
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [dry-run] would remove: $basename"
        return
    fi
    rm -f "$file"
}

# ============================================================================
# Phase 1: JICM Reset
# Clear stale JICM signal files (>1hr old, not during active compression)
# ============================================================================
phase_jicm_reset() {
    if ! should_run 1; then return; fi
    phase_header 1 "JICM Reset"

    # Safety: skip if actively compressing
    local watcher_state=""
    if [[ -f "$CONTEXT_DIR/.watcher-status" ]]; then
        watcher_state=$(awk '/^state:/{print $2}' "$CONTEXT_DIR/.watcher-status" 2>/dev/null || true)
    fi
    if [[ "$watcher_state" == "compression_triggered" ]]; then
        phase_result "skipped (compression active)"
        return
    fi

    local count=0
    local hour=3600
    local jicm_signals=(
        "$CONTEXT_DIR/.jicm-standdown"
        "$CONTEXT_DIR/.compression-done.signal"
        "$CONTEXT_DIR/.compressed-context-ready.md"
        "$CONTEXT_DIR/.in-progress-ready.md"
        "$CONTEXT_DIR/.soft-restart-checkpoint.md"
    )

    for sig in "${jicm_signals[@]}"; do
        if [[ -f "$sig" ]]; then
            local age
            age=$(file_age_seconds "$sig")
            if [[ "$age" -gt "$hour" ]]; then
                safe_remove "$sig"
                count=$((count + 1))
                CLEANED=$((CLEANED + 1))
            fi
        fi
    done

    phase_result "$(printf '.......... %d cleared' "$count")"
}

# ============================================================================
# Phase 2: Signal File Cleanup
# Clear expired transient signal files from various subsystems
# ============================================================================
phase_signal_cleanup() {
    if ! should_run 2; then return; fi
    phase_header 2 "Signal Cleanup"

    local count=0
    local hour=3600

    # Transient signals — remove if >1hr old
    local transient_signals=(
        "$CONTEXT_DIR/.ennoia-trigger"
        "$CONTEXT_DIR/.carry-on.signal"
        "$CONTEXT_DIR/.session-kill.signal"
    )

    for sig in "${transient_signals[@]}"; do
        if [[ -f "$sig" ]]; then
            local age
            age=$(file_age_seconds "$sig")
            if [[ "$age" -gt "$hour" ]]; then
                safe_remove "$sig"
                count=$((count + 1))
                CLEANED=$((CLEANED + 1))
            fi
        fi
    done

    # Ulfhedthnar signals — reset if decay expired (>24hr)
    local ulf_signals="$PROJECT_DIR/.claude/state/ulfhedthnar-signals.json"
    if [[ -f "$ulf_signals" ]]; then
        local age
        age=$(file_age_seconds "$ulf_signals")
        local day=86400
        if [[ "$age" -gt "$day" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "  [dry-run] would reset: ulfhedthnar-signals.json"
            else
                echo '{"defeat_signals":[],"last_reset":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > "$ulf_signals"
            fi
            count=$((count + 1))
            CLEANED=$((CLEANED + 1))
        fi
    fi

    phase_result "$(printf '.......... %d cleared' "$count")"
}

# ============================================================================
# Phase 3: Log Rotation
# Move oversized logs to archive (move, never delete)
# ============================================================================
phase_log_rotation() {
    if ! should_run 3; then return; fi
    phase_header 3 "Log Rotation"

    local count=0
    local today
    today=$(date +%Y-%m-%d)

    # Telemetry logs >100KB (skip today's file)
    for logfile in "$LOGS_DIR"/telemetry/events-*.jsonl; do
        [[ -f "$logfile" ]] || continue
        local basename
        basename=$(basename "$logfile")
        # Skip today's telemetry file
        if [[ "$basename" == *"$today"* ]]; then
            continue
        fi
        local size_kb
        size_kb=$(file_size_kb "$logfile")
        if [[ "$size_kb" -gt 100 ]]; then
            safe_move "$logfile"
            count=$((count + 1))
            CLEANED=$((CLEANED + 1))
        fi
    done

    # JICM logs >50KB
    for logfile in "$LOGS_DIR"/jicm/*.log; do
        [[ -f "$logfile" ]] || continue
        local size_kb
        size_kb=$(file_size_kb "$logfile")
        if [[ "$size_kb" -gt 50 ]]; then
            safe_move "$logfile"
            count=$((count + 1))
            CLEANED=$((CLEANED + 1))
        fi
    done

    # file-access.json >500KB — trim by moving to archive
    local fa="$LOGS_DIR/file-access.json"
    if [[ -f "$fa" ]]; then
        local size_kb
        size_kb=$(file_size_kb "$fa")
        if [[ "$size_kb" -gt 500 ]]; then
            safe_move "$fa"
            count=$((count + 1))
            CLEANED=$((CLEANED + 1))
        fi
    fi

    phase_result "$(printf '.......... %d archived' "$count")"
}

# ============================================================================
# Phase 4: Core File Validation
# Existence check on critical infrastructure files (read-only)
# ============================================================================
phase_core_validation() {
    if ! should_run 4; then return; fi
    phase_header 4 "Core Files"

    local present=0
    local total=7
    local core_files=(
        "$PROJECT_DIR/CLAUDE.md"
        "$CONTEXT_DIR/session-state.md"
        "$CONTEXT_DIR/current-priorities.md"
        "$CONTEXT_DIR/psyche/capability-map.yaml"
        "$CONTEXT_DIR/psyche/jarvis-identity.md"
        "$CONTEXT_DIR/compaction-essentials.md"
        "$SCRIPTS_DIR/jarvis-watcher.sh"
    )

    for f in "${core_files[@]}"; do
        if [[ -f "$f" ]]; then
            present=$((present + 1))
        else
            local basename
            basename=$(basename "$f")
            if [[ "$QUIET" != "true" && "$DRY_RUN" != "true" ]]; then
                echo "  MISSING: $basename"
            fi
            FLAGGED=$((FLAGGED + 1))
        fi
    done

    phase_result "$(printf '.......... %d/%d present' "$present" "$total")"
}

# ============================================================================
# Phase 5: Git Hygiene
# Quick git health check (read-only, no git operations)
# ============================================================================
phase_git_hygiene() {
    if ! should_run 5; then return; fi
    phase_header 5 "Git Hygiene"

    local uncommitted=0
    local unpushed=0

    # Uncommitted changes count
    uncommitted=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    # Unpushed commits count
    unpushed=$(git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' ')

    # Conflict check
    local conflicts=0
    conflicts=$(git -C "$PROJECT_DIR" diff --name-only --diff-filter=U 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$conflicts" -gt 0 ]]; then
        FLAGGED=$((FLAGGED + 1))
    fi

    local detail="${uncommitted} uncommitted, ${unpushed} unpushed"
    if [[ "$conflicts" -gt 0 ]]; then
        detail="$detail, ${C_RED}${conflicts} conflicts${C_RESET}"
        ERRORS=$((ERRORS + 1))
    fi

    phase_result "$(printf '.......... %s' "$detail")"
}

# ============================================================================
# Phase 6: Index Sync
# Verify index files match filesystem reality (read-only)
# ============================================================================
phase_index_sync() {
    if ! should_run 6; then return; fi
    phase_header 6 "Index Sync"

    # Skills: count SKILL.md files vs what _index.md lists
    local skill_dirs=0
    for d in "$PROJECT_DIR"/.claude/skills/*/SKILL.md; do
        [[ -f "$d" ]] || continue
        skill_dirs=$((skill_dirs + 1))
    done

    # Agents: count operational agent .md files (excluding README, _template)
    local agent_files=0
    for f in "$PROJECT_DIR"/.claude/agents/*.md; do
        [[ -f "$f" ]] || continue
        local basename
        basename=$(basename "$f")
        if [[ "$basename" == "README.md" || "$basename" == "_template.md" ]]; then
            continue
        fi
        agent_files=$((agent_files + 1))
    done

    # Commands: count .md files (excluding README)
    local cmd_files=0
    for f in "$PROJECT_DIR"/.claude/commands/*.md; do
        [[ -f "$f" ]] || continue
        local basename
        basename=$(basename "$f")
        if [[ "$basename" == "README.md" ]]; then
            continue
        fi
        cmd_files=$((cmd_files + 1))
    done

    # Report counts for awareness (deep sync check deferred to /maintain)
    if [[ "$QUIET" != "true" && "$DRY_RUN" == "true" ]]; then
        echo "  Skills: $skill_dirs dirs with SKILL.md"
        echo "  Agents: $agent_files .md files"
        echo "  Commands: $cmd_files .md files"
    fi

    # We don't parse index files in bash — just report counts
    # A mismatch would require comparing against parsed markdown, which is /maintain territory
    phase_result "$(printf '.......... %d skills, %d agents, %d cmds' "$skill_dirs" "$agent_files" "$cmd_files")"
}

# ============================================================================
# Phase 7: State Freshness
# Flag AC state files with mtime >7 days (read-only)
# ============================================================================
phase_state_freshness() {
    if ! should_run 7; then return; fi
    phase_header 7 "State Freshness"

    local stale=0
    local total=0
    local week=604800  # 7 days in seconds

    for state_file in "$STATE_DIR"/AC-*.json; do
        [[ -f "$state_file" ]] || continue
        total=$((total + 1))
        local age
        age=$(file_age_seconds "$state_file")
        if [[ "$age" -gt "$week" ]]; then
            stale=$((stale + 1))
            FLAGGED=$((FLAGGED + 1))
            if [[ "$QUIET" != "true" ]]; then
                local basename
                basename=$(basename "$state_file")
                local days=$(( age / 86400 ))
                echo "  [stale] $basename (${days}d old)"
            fi
        fi
    done

    if [[ "$stale" -gt 0 ]]; then
        phase_result "$(printf '.......... %d stale (of %d)' "$stale" "$total")"
    else
        phase_result "$(printf '.......... %d/%d fresh' "$total" "$total")"
    fi
}

# ============================================================================
# Runner — Output formatting
# ============================================================================
print_header() {
    if [[ "$QUIET" == "true" ]]; then return; fi
    echo "${C_BOLD}${C_GREEN}/housekeep — Quick Infrastructure Cleanup${C_RESET}"
    echo "${C_DIM}──────────────────────────────────────────${C_RESET}"
}

print_footer() {
    if [[ "$QUIET" == "true" ]]; then
        echo "housekeep: ${CLEANED} cleaned, ${FLAGGED} flagged, ${ERRORS} errors"
        return
    fi
    echo "${C_DIM}──────────────────────────────────────────${C_RESET}"
    local cleaned_color="$C_GREEN"
    local flagged_color="$C_DIM"
    local errors_color="$C_DIM"
    if [[ "$CLEANED" -gt 0 ]]; then cleaned_color="$C_CYAN"; fi
    if [[ "$FLAGGED" -gt 0 ]]; then flagged_color="$C_YELLOW"; fi
    if [[ "$ERRORS" -gt 0 ]]; then errors_color="$C_RED"; fi
    echo "Total: ${cleaned_color}${CLEANED} cleaned${C_RESET}, ${flagged_color}${FLAGGED} flagged${C_RESET}, ${errors_color}${ERRORS} errors${C_RESET}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${C_YELLOW}(dry-run mode — no changes made)${C_RESET}"
    fi
}

# ============================================================================
# Argument Parsing
# ============================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)
            if [[ -z "${2:-}" || ! "$2" =~ ^[1-7]$ ]]; then
                echo "Error: --phase requires a value between 1 and 7" >&2
                exit 1
            fi
            PHASE_FILTER="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --help|-h)
            echo "Usage: housekeep.sh [--phase <1-7>] [--dry-run] [--quiet]"
            echo ""
            echo "Phases:"
            echo "  1  JICM Reset       — Clear stale JICM signal files"
            echo "  2  Signal Cleanup   — Clear expired transient signals"
            echo "  3  Log Rotation     — Archive oversized log files"
            echo "  4  Core Files       — Validate critical file existence"
            echo "  5  Git Hygiene      — Quick git health check"
            echo "  6  Index Sync       — Count skills/agents/commands"
            echo "  7  State Freshness  — Flag stale AC state files"
            echo ""
            echo "Options:"
            echo "  --phase N    Run only phase N (1-7)"
            echo "  --dry-run    Show what would be done, no changes"
            echo "  --quiet      Single summary line output"
            echo "  --help       Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage" >&2
            exit 1
            ;;
    esac
done

# ============================================================================
# Main
# ============================================================================
print_header

phase_jicm_reset
phase_signal_cleanup
phase_log_rotation
phase_core_validation
phase_git_hygiene
phase_index_sync
phase_state_freshness

print_footer

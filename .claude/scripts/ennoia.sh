#!/usr/bin/env bash
# ennoia.sh — Session Orchestrator Aion Script v0.2
# Runs in tmux jarvis:2, 30s refresh cycle
# Writes: .ennoia-status (dashboard state), .ennoia-recommendation (Watcher handoff)
#
# Design: .claude/plans/ennoia-aion-script-design.md (27 iterations)
# Architecture: Ennoia = intent layer (what should I do?)
#   - Watcher = defensive awareness (am I safe?)
#   - Virgil = navigational awareness (what am I looking at?)
#   - Ennoia = intentional awareness (what should I do next?)
#
# v0.1: Dashboard only (display). No scheduler, no auto-actions.
# v0.2: Writes .ennoia-recommendation signal file for Watcher consumption.
#        Watcher reads recommendation for wake-up prompt text (graceful fallback).
# v0.3+: session-start.sh thin dispatcher, idle scheduler

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
SESSION_STATE="$PROJECT_DIR/.claude/context/session-state.md"
PRIORITIES="$PROJECT_DIR/.claude/context/current-priorities.md"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
ENNOIA_STATE="$PROJECT_DIR/.claude/context/.ennoia-state"
ENNOIA_STATUS="$PROJECT_DIR/.claude/context/.ennoia-status"
ENNOIA_RECOMMENDATION="$PROJECT_DIR/.claude/context/.ennoia-recommendation"
REFRESH=30

# --- Color Constants (ANSI-C quoting for reliable escape sequences) ---
C_RESET=$'\e[0m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_MAGENTA=$'\e[35m'

# Trap for clean exit
trap 'echo "Ennoia: shutting down."; exit 0' SIGTERM SIGINT

# Initialize state if first run
init_state() {
    if [[ ! -f "$ENNOIA_STATE" ]]; then
        cat > "$ENNOIA_STATE" <<EOF
version: 1
session_count: 1
last_session_end: null
maintenance:
  last_reflect: null
  last_maintain: null
  last_evolve: null
  last_research: null
EOF
    fi
}

# Determine mode: arise, attend, idle, or resume
detect_mode() {
    local watcher_state
    watcher_state=$(awk '/^state:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)

    # If watcher just cleared → resume mode (brief)
    if [[ "$watcher_state" == "cleared" ]]; then
        echo "resume"
        return 0
    fi

    # Check if session just started (uptime < 2 min)
    local start_time now uptime_secs
    start_time=$(stat -f %m "$ENNOIA_STATUS" 2>/dev/null || echo 0)
    now=$(date +%s)
    uptime_secs=$(( now - start_time ))
    if [[ $uptime_secs -lt 120 ]]; then
        echo "arise"
        return 0
    fi

    # Check idle (no file-access.json updates for 5+ min)
    local fa_mtime idle_seconds
    fa_mtime=$(stat -f %m "$PROJECT_DIR/.claude/logs/file-access.json" 2>/dev/null || echo 0)
    idle_seconds=$(( now - fa_mtime ))
    if [[ $idle_seconds -gt 300 ]]; then
        echo "idle"
        return 0
    fi

    echo "attend"
    return 0
}

# Get session intent from session-state.md
get_intent() {
    grep "Status" "$SESSION_STATE" 2>/dev/null | head -1 | sed 's/.*: //'
}

# Get current work description from session-state.md (for recommendations)
# Strips markdown bold, emoji, leading whitespace. Truncates to 80 chars.
get_current_work() {
    local status_line
    status_line=$(grep -m1 '^\*\*Status\*\*' "$SESSION_STATE" 2>/dev/null \
        | sed 's/\*\*Status\*\*:[[:space:]]*//' \
        | LC_ALL=C sed 's/[^[:print:][:space:]]//g' \
        | sed 's/^[[:space:]]*//' || echo "")
    if [[ -n "$status_line" ]]; then
        echo "${status_line:0:80}"
    else
        echo "unknown"
    fi
    return 0
}

# Get next priority from current-priorities.md
# Looks for **Next**: lines or first ### heading under ## Up Next
get_next_priority() {
    local next_line
    # Try explicit **Next**: field first
    next_line=$(grep -m1 '\*\*Next\*\*' "$PRIORITIES" 2>/dev/null \
        | sed 's/.*\*\*Next\*\*:[[:space:]]*//' \
        | sed 's/\*\*//g' || echo "")
    if [[ -n "$next_line" ]]; then
        echo "${next_line:0:60}"
        return 0
    fi
    # Fallback: first ### under ## Up Next
    next_line=$(awk '/^## Up Next/{found=1; next} found && /^### /{print; exit}' "$PRIORITIES" 2>/dev/null \
        | sed 's/^### //' || echo "")
    if [[ -n "$next_line" ]]; then
        echo "${next_line:0:60}"
        return 0
    fi
    echo ""
    return 0
}

# Write .ennoia-recommendation signal file for Watcher consumption
# Atomic write: tmp file → mv (prevents Watcher reading partial content)
# Only writes for arise and resume modes (attend/idle = no recommendation)
write_recommendation() {
    local mode="$1"
    local recommendation=""

    case "$mode" in
        arise)
            local current_work next_priority
            current_work=$(get_current_work)
            next_priority=$(get_next_priority)
            if [[ -n "$next_priority" ]]; then
                recommendation="[SESSION-START] New session. Current: ${current_work}. Next: ${next_priority}. Read .claude/context/session-state.md + .claude/context/current-priorities.md, begin work. Do NOT just greet."
            else
                recommendation="[SESSION-START] New session. Current: ${current_work}. Read .claude/context/session-state.md + .claude/context/current-priorities.md, begin work. Do NOT just greet."
            fi
            ;;
        resume)
            recommendation="[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md, .claude/context/.in-progress-ready.md, and .claude/context/session-state.md — resume work immediately. Do NOT greet."
            ;;
        attend|idle)
            # No recommendation for attend (working) or idle (Phase J scope)
            return 0
            ;;
    esac

    if [[ -n "$recommendation" ]]; then
        # Atomic write: write to tmp, then mv
        echo "$recommendation" > "${ENNOIA_RECOMMENDATION}.tmp"
        mv "${ENNOIA_RECOMMENDATION}.tmp" "$ENNOIA_RECOMMENDATION"
    fi

    return 0
}

# Get maintenance status from report directories
get_maintenance_status() {
    local reflect_log="$PROJECT_DIR/.claude/reports/reflections"
    local maintain_log="$PROJECT_DIR/.claude/reports/maintenance"

    local now reflect_age maintain_age
    now=$(date +%s)
    reflect_age="never"
    maintain_age="never"

    if [[ -d "$reflect_log" ]]; then
        local latest
        latest=$(ls -t "$reflect_log"/*.md 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            local mtime days
            mtime=$(stat -f %m "$latest")
            days=$(( (now - mtime) / 86400 ))
            reflect_age="${days}d ago"
        fi
    fi

    if [[ -d "$maintain_log" ]]; then
        local latest
        latest=$(ls -t "$maintain_log"/*.md 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            local mtime days
            mtime=$(stat -f %m "$latest")
            days=$(( (now - mtime) / 86400 ))
            maintain_age="${days}d ago"
        fi
    fi

    echo "reflect:$reflect_age maintain:$maintain_age"
}

# Render dashboard
render() {
    local mode
    mode=$(detect_mode)
    local cols
    cols=$(tput cols 2>/dev/null || echo 55)

    tput cup 0 0 2>/dev/null
    tput ed 2>/dev/null

    # Header
    printf "${C_BOLD}${C_MAGENTA} ENNOIA${C_RESET} — Session Orchestrator"
    printf '%*s\n' $((cols - 35)) "$(date '+%H:%M %Z')"
    printf '%.0s─' $(seq 1 "$cols"); echo

    case "$mode" in
        arise)
            echo; echo "${C_BOLD}  SESSION INTENT${C_RESET}"
            echo "  → $(get_intent)"
            local unpushed
            unpushed=$(git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' ')
            [[ $unpushed -gt 0 ]] && echo "  → $unpushed commits unpushed"
            local branch
            branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
            echo "  → Branch: ${branch:-unknown}"

            echo; echo "${C_BOLD}  MAINTENANCE QUEUE${C_RESET}"
            local maint
            maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        attend)
            echo; echo "  CURRENT: $(get_intent)"
            local pct
            pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
            echo "  Context: ${pct:-?}"
            ;;

        idle)
            echo; echo "${C_YELLOW}  IDLE${C_RESET} — Evaluating maintenance queue..."
            local maint
            maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        resume)
            echo; echo "  Resuming after context compression..."
            echo "  Reading compressed context..."
            ;;
    esac

    # Write recommendation signal file for Watcher
    write_recommendation "$mode"

    # Footer
    printf '\n%.0s─' $(seq 1 "$cols"); echo
    local tokens pct rec_indicator
    tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    rec_indicator=""
    [[ -f "$ENNOIA_RECOMMENDATION" ]] && rec_indicator=" | REC: ready"
    printf '  Mode: %s | Context: %s (%s)%s\n' "$mode" "${pct:-?}" "${tokens:-?}" "$rec_indicator"

    # Update status file
    local has_rec="false"
    [[ -f "$ENNOIA_RECOMMENDATION" ]] && has_rec="true"
    cat > "$ENNOIA_STATUS" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
version: 0.2
mode: $mode
intent: $(get_intent)
recommendation_active: $has_rec
EOF
}

# Main
init_state
while true; do
    render 2>/dev/null || true
    sleep "$REFRESH"
done

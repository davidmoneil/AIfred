#!/usr/bin/env bash
# ennoia.sh — Session Orchestrator Aion Script v0.1
# Runs in tmux jarvis:3, 30s refresh cycle
# Read-only (except .ennoia-status), no keystroke injection
#
# Design: .claude/plans/ennoia-aion-script-design.md (27 iterations)
# Architecture: Ennoia = intent layer (what should I do?)
#   - Watcher = defensive awareness (am I safe?)
#   - Virgil = navigational awareness (what am I looking at?)
#   - Ennoia = intentional awareness (what should I do next?)
#
# v0.1 scope: Dashboard only (display). No scheduler, no auto-actions.
# v0.2+: Idle scheduler, .ennoia-recommendation signal file

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
SESSION_STATE="$PROJECT_DIR/.claude/context/session-state.md"
PRIORITIES="$PROJECT_DIR/.claude/context/current-priorities.md"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
ENNOIA_STATE="$PROJECT_DIR/.claude/context/.ennoia-state"
ENNOIA_STATUS="$PROJECT_DIR/.claude/context/.ennoia-status"
ENNOIA_RECOMMENDATION="$PROJECT_DIR/.claude/context/.ennoia-recommendation"
REFRESH=30

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
    printf '\e[1;35m ENNOIA\e[0m — Session Orchestrator'
    printf '%*s\n' $((cols - 35)) "$(date '+%H:%M %Z')"
    printf '%.0s─' $(seq 1 "$cols"); echo

    case "$mode" in
        arise)
            echo -e "\n\e[1m  SESSION INTENT\e[0m"
            echo "  → $(get_intent)"
            local unpushed
            unpushed=$(git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' ')
            [[ $unpushed -gt 0 ]] && echo "  → $unpushed commits unpushed"
            local branch
            branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
            echo "  → Branch: ${branch:-unknown}"

            echo -e "\n\e[1m  MAINTENANCE QUEUE\e[0m"
            local maint
            maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        attend)
            echo -e "\n  CURRENT: $(get_intent)"
            local pct
            pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
            echo "  Context: ${pct:-?}"
            ;;

        idle)
            echo -e "\n\e[33m  IDLE\e[0m — Evaluating maintenance queue..."
            local maint
            maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        resume)
            echo -e "\n  Resuming after context compression..."
            echo "  Reading compressed context..."
            ;;
    esac

    # Footer
    printf '\n%.0s─' $(seq 1 "$cols"); echo
    local tokens pct
    tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    printf '  Mode: %s │ Context: %s (%s)\n' "$mode" "${pct:-?}" "${tokens:-?}"

    # Update status file (only file Ennoia writes)
    cat > "$ENNOIA_STATUS" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
mode: $mode
intent: $(get_intent)
EOF
}

# Main
init_state
while true; do
    render 2>/dev/null || true
    sleep "$REFRESH"
done

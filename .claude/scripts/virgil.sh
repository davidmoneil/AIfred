#!/usr/bin/env bash
# virgil.sh — Codebase Guide Aion Script v0.2
# Runs in tmux jarvis:3, 15s refresh cycle
# Read-only, no LLM calls, deterministic heuristics
#
# Design: .claude/plans/virgil-angel-script-design.md (20 iterations)
# Architecture: Virgil = navigational awareness (what am I looking at?)
#   - Shows codebase through the AI's eyes
#   - Task and agent tracking via virgil-tracker.js signal files
#   - OSC 8 hyperlinks (clickable in iTerm2 tmux panes)
#   - "Virgil Says" heuristic recommendations
#
# Prerequisites:
#   tmux: set -g allow-passthrough on
#   tmux: set -as terminal-features ',xterm-256color:hyperlinks'
#
# v0.2 — F.2 MVP: TASKS, ACTIVE AGENTS, FILES TOUCHED panels

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
FILE_ACCESS="$PROJECT_DIR/.claude/logs/file-access.json"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
ENNOIA_STATUS="$PROJECT_DIR/.claude/context/.ennoia-status"
VIRGIL_TASKS="$PROJECT_DIR/.claude/context/.virgil-tasks.json"
VIRGIL_AGENTS="$PROJECT_DIR/.claude/context/.virgil-agents.json"
REFRESH=15  # seconds

# Trap for clean exit
trap 'echo "Virgil: shutting down."; exit 0' SIGTERM SIGINT

# --- Color Constants (ANSI-C quoting for reliable escape sequences) ---
C_RESET=$'\e[0m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_RED=$'\e[31m'
C_CYAN=$'\e[36m'
C_MAGENTA=$'\e[35m'

# --- OSC 8 Hyperlink Helpers ---
hyperlink() { printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$1" "$2"; }
file_link() {
    local abs="$PROJECT_DIR/$1" display="${2:-$1}"
    hyperlink "vscode://file${abs}" "$display"
}

# --- Data Extraction ---
get_recent_files() {
    # Top 8 files by last_read within 10 min, using python3 for JSON
    python3 -c "
import json, sys
from datetime import datetime, timedelta, timezone
try:
    d = json.load(open(sys.argv[1]))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)
cutoff = datetime.now(timezone.utc) - timedelta(minutes=10)
recent = []
for path, info in d.get('files', {}).items():
    try:
        lr = datetime.fromisoformat(info['last_read'].replace('Z','+00:00'))
        if lr > cutoff:
            recent.append((lr, path, info.get('read_count', 1)))
    except (KeyError, ValueError):
        continue
recent.sort(reverse=True)
for lr, path, count in recent[:8]:
    print(f'{count}\t{path}')
" "$FILE_ACCESS" 2>/dev/null
}

get_unpushed() { git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' '; }

# --- Tasks Section (reads .virgil-tasks.json) ---
render_tasks_section() {
    echo; echo "${C_BOLD} TASKS${C_RESET}"
    if [[ ! -f "$VIRGIL_TASKS" ]]; then
        echo "  ${C_DIM}(no active tasks)${C_RESET}"
        return
    fi
    local output
    output=$(python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)
tasks = d.get('tasks', [])
if not tasks:
    print('  (no active tasks)')
    sys.exit(0)
icons = {'completed': '[x]', 'in_progress': '[>]', 'pending': '[ ]', 'deleted': '[-]'}
colors = {'completed': '\\033[32m', 'in_progress': '\\033[33m', 'pending': '\\033[0m', 'deleted': '\\033[2m'}
reset = '\\033[0m'
for t in tasks[:8]:
    s = t.get('status', 'pending')
    icon = icons.get(s, '[ ]')
    color = colors.get(s, '')
    subj = t.get('subject', '?')[:50]
    tid = t.get('id', '?')
    extra = ''
    if s == 'in_progress':
        af = t.get('activeForm', '')
        if af:
            extra = f' ({af})'
    print(f'  {color}{icon} #{tid} {subj}{extra}{reset}')
" "$VIRGIL_TASKS" 2>/dev/null)
    if [[ -n "$output" ]]; then
        echo "$output"
    else
        echo "  ${C_DIM}(no active tasks)${C_RESET}"
    fi
}

# --- Active Agents Section (reads .virgil-agents.json) ---
render_agents_section() {
    echo; echo "${C_BOLD} AGENTS${C_RESET}"
    if [[ ! -f "$VIRGIL_AGENTS" ]]; then
        echo "  ${C_DIM}(no active agents)${C_RESET}"
        return
    fi
    local output
    output=$(python3 -c "
import json, sys
from datetime import datetime, timezone
try:
    d = json.load(open(sys.argv[1]))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)
agents = d.get('agents', [])
if not agents:
    print('  (no active agents)')
    sys.exit(0)
now = datetime.now(timezone.utc)
for a in agents:
    atype = a.get('type', '?')
    desc = a.get('description', '')[:40]
    status = a.get('status', 'running')
    started = a.get('started', '')
    elapsed = ''
    stale = ''
    if started:
        try:
            st = datetime.fromisoformat(started.replace('Z','+00:00'))
            secs = int((now - st).total_seconds())
            if secs < 60:
                elapsed = f'{secs}s'
            else:
                elapsed = f'{secs // 60}m{secs % 60:02d}s'
            if secs > 600 and status == 'running':
                stale = ' \\033[31m(possibly stalled)\\033[0m'
        except (ValueError, TypeError):
            pass
    icon = '\\033[33m*' if status == 'running' else '\\033[32mv'
    reset = '\\033[0m'
    print(f'  {icon}{reset} {atype}: {desc} [{elapsed}]{stale}')
" "$VIRGIL_AGENTS" 2>/dev/null)
    if [[ -n "$output" ]]; then
        echo "$output"
    else
        echo "  ${C_DIM}(no active agents)${C_RESET}"
    fi
}

# --- Files Touched Section (enhanced git changes) ---
render_files_touched() {
    echo; echo "${C_BOLD} FILES TOUCHED${C_RESET}"
    local changes
    changes=$(git -C "$PROJECT_DIR" status --short 2>/dev/null)
    if [[ -z "$changes" ]]; then
        echo "  ${C_DIM}(clean working tree)${C_RESET}"
        return
    fi
    # Group and color by status
    echo "$changes" | head -12 | while IFS= read -r line; do
        local status="${line:0:2}"
        local file="${line:3}"
        case "$status" in
            "M "| " M"|"MM") printf "  ${C_YELLOW}M${C_RESET}  %s\n" "$file" ;;
            "A "| " A")      printf "  ${C_GREEN}A${C_RESET}  %s\n" "$file" ;;
            "D "| " D")      printf "  ${C_RED}D${C_RESET}  %s\n" "$file" ;;
            "??")            printf "  ${C_DIM}?  %s${C_RESET}\n" "$file" ;;
            "R ")            printf "  ${C_MAGENTA}R${C_RESET}  %s\n" "$file" ;;
            *)               printf "  %s  %s\n" "$status" "$file" ;;
        esac
    done
    local total
    total=$(echo "$changes" | wc -l | tr -d ' ')
    if [[ "$total" -gt 12 ]]; then
        echo "  ${C_DIM}... and $((total - 12)) more${C_RESET}"
    fi
}

# --- Virgil Says (highest priority rule wins) ---
virgil_says() {
    local pct unpushed tasks_count agents_running
    pct=$(awk '/^percentage:/{gsub(/%/,""); print $2}' "$WATCHER_STATUS" 2>/dev/null)
    unpushed=$(get_unpushed)
    # Check for stalled agents
    agents_running=$(python3 -c "
import json, sys
from datetime import datetime, timezone
try:
    d = json.load(open(sys.argv[1]))
    agents = [a for a in d.get('agents', []) if a.get('status') == 'running']
    stalled = 0
    now = datetime.now(timezone.utc)
    for a in agents:
        try:
            st = datetime.fromisoformat(a['started'].replace('Z','+00:00'))
            if (now - st).total_seconds() > 600:
                stalled += 1
        except (KeyError, ValueError, TypeError):
            pass
    if stalled > 0:
        print(f'stalled:{stalled}')
    elif agents:
        print(f'running:{len(agents)}')
except Exception:
    pass
" "$VIRGIL_AGENTS" 2>/dev/null)

    if [[ "${pct:-0}" -ge 70 ]]; then
        echo "Context at ${pct}%. Compression imminent."
    elif [[ "$agents_running" == stalled:* ]]; then
        local n="${agents_running#stalled:}"
        echo "${n} agent(s) possibly stalled (>10 min)."
    elif [[ "${unpushed:-0}" -gt 0 ]]; then
        echo "${unpushed} commit(s) unpushed to remote."
    elif [[ "$agents_running" == running:* ]]; then
        local n="${agents_running#running:}"
        echo "${n} agent(s) actively working."
    else
        echo "All systems nominal."
    fi
}

# --- Ennoia Section (reads .ennoia-status if available) ---
render_ennoia_section() {
    if [[ -f "$ENNOIA_STATUS" ]]; then
        local mode intent
        mode=$(awk '/^mode:/{print $2}' "$ENNOIA_STATUS" 2>/dev/null)
        intent=$(sed -n 's/^intent: //p' "$ENNOIA_STATUS" 2>/dev/null | head -1)
        echo; echo "${C_BOLD} ENNOIA${C_RESET}"
        echo "  Mode: ${mode:-?} | Intent: ${intent:-?}"
    fi
}

# --- Render ---
render() {
    clear
    local cols
    cols=$(tput cols 2>/dev/null || echo 60)
    printf "${C_BOLD}${C_CYAN} VIRGIL${C_RESET} — Codebase Guide"
    printf '%*s' $((cols - 30)) "$(date '+%H:%M %Z')"
    echo; printf '%.0s─' $(seq 1 "$cols"); echo

    # Panels: Tasks → Agents → Files Touched → Recent Files → Context → Ennoia
    render_tasks_section
    render_agents_section
    render_files_touched

    echo; echo "${C_BOLD} RECENT FILES (last 10 min)${C_RESET}"
    local files
    files=$(get_recent_files)
    if [[ -n "$files" ]]; then
        while IFS=$'\t' read -r count path; do
            printf '  %3dx  ' "$count"
            file_link "$path" "$path"
            echo
        done <<< "$files"
    else
        echo "  ${C_DIM}(no recent file activity)${C_RESET}"
    fi

    echo; echo "${C_BOLD} CONTEXT${C_RESET}"
    local tokens pct state
    tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    state=$(awk '/^state:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    echo "  Tokens: ${tokens:-?} (${pct:-?}) | State: ${state:-?}"

    render_ennoia_section

    printf '\n%.0s─' $(seq 1 "$cols"); echo
    printf '\e[33m ☞ Virgil says:\e[0m %s\n' "$(virgil_says)"
}

# --- Main Loop ---
while true; do
    render
    sleep "$REFRESH"
done

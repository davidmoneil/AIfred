#!/usr/bin/env bash
# virgil.sh — Codebase Guide Aion Script v0.1
# Runs in tmux jarvis:2, 15s refresh cycle
# Read-only, no LLM calls, deterministic heuristics
#
# Design: .claude/plans/virgil-angel-script-design.md (20 iterations)
# Architecture: Virgil = navigational awareness (what am I looking at?)
#   - Shows codebase through the AI's eyes
#   - OSC 8 hyperlinks (clickable in iTerm2 tmux panes)
#   - "Virgil Says" heuristic recommendations
#
# Prerequisites:
#   tmux: set -g allow-passthrough on
#   tmux: set -as terminal-features ',xterm-256color:hyperlinks'

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
FILE_ACCESS="$PROJECT_DIR/.claude/logs/file-access.json"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
ENNOIA_STATUS="$PROJECT_DIR/.claude/context/.ennoia-status"
REFRESH=15  # seconds

# Trap for clean exit
trap 'echo "Virgil: shutting down."; exit 0' SIGTERM SIGINT

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
    d = json.load(open('$FILE_ACCESS'))
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
" 2>/dev/null
}

get_git_changes() { git -C "$PROJECT_DIR" status --short 2>/dev/null; }
get_unpushed()    { git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' '; }

# --- Virgil Says (highest priority rule wins) ---
virgil_says() {
    local pct unpushed
    pct=$(awk '/^percentage:/{gsub(/%/,""); print $2}' "$WATCHER_STATUS" 2>/dev/null)
    unpushed=$(get_unpushed)
    if [[ "${pct:-0}" -ge 70 ]]; then
        echo "Context at ${pct}%. Compression imminent."
    elif [[ "${unpushed:-0}" -gt 0 ]]; then
        echo "${unpushed} commit(s) unpushed to remote."
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
        echo -e "\n\e[1m ENNOIA\e[0m"
        echo "  Mode: ${mode:-?} | Intent: ${intent:-?}"
    fi
}

# --- Render ---
render() {
    clear
    local cols
    cols=$(tput cols 2>/dev/null || echo 60)
    printf '\e[1;36m VIRGIL\e[0m — Codebase Guide'
    printf '%*s' $((cols - 30)) "$(date '+%H:%M %Z')"
    echo; printf '%.0s─' $(seq 1 "$cols"); echo

    echo -e "\n\e[1m RECENT FILES (last 10 min)\e[0m"
    local files
    files=$(get_recent_files)
    if [[ -n "$files" ]]; then
        while IFS=$'\t' read -r count path; do
            printf '  %3dx  ' "$count"
            file_link "$path" "$path"
            echo
        done <<< "$files"
    else
        echo "  (no recent file activity)"
    fi

    echo -e "\n\e[1m CHANGES (uncommitted)\e[0m"
    local changes
    changes=$(get_git_changes)
    if [[ -n "$changes" ]]; then
        echo "$changes" | head -10 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  (clean working tree)"
    fi

    echo -e "\n\e[1m CONTEXT\e[0m"
    local tokens pct state
    tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    state=$(awk '/^state:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    echo "  Tokens: ${tokens:-?} (${pct:-?}) | State: ${state:-?}"

    # Ennoia integration (v0.1 pragmatic: Section 28 of Ennoia design)
    render_ennoia_section

    printf '\n%.0s─' $(seq 1 "$cols"); echo
    printf '\e[33m ☞ Virgil says:\e[0m %s\n' "$(virgil_says)"
}

# --- Main Loop ---
while true; do
    render
    sleep "$REFRESH"
done

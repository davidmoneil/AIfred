#!/bin/bash
# update-priorities.sh - Data gathering for priority validation
# Part of the Capability Layering Pattern - deterministic operations only
#
# Usage:
#   update-priorities.sh --git-history [days]     # Git commits as JSON
#   update-priorities.sh --session-notes [count]  # Recent session notes
#   update-priorities.sh --system-state           # Docker, MCP, SSH status
#   update-priorities.sh --parse-priorities       # Parse priorities.md to JSON
#   update-priorities.sh --search <term>          # Search priorities for term
#   update-priorities.sh --evidence <term>        # Gather evidence for item
#   update-priorities.sh --summary                # Quick summary stats
#
# Output: JSON for structured consumption by Claude
#
# Created: 2026-01-21

set -euo pipefail

# Configuration
AIFRED_HOME="${AIFRED_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"
PRIORITIES_FILE="$AIFRED_HOME/.claude/context/projects/current-priorities.md"
SESSION_NOTES_DIR="$AIFRED_HOME/knowledge/notes"
SESSION_STATE_FILE="$AIFRED_HOME/.claude/context/session-state.md"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Commands:
  --git-history [days]      Get git commits (default: 30 days)
  --session-notes [count]   List recent session notes (default: 5)
  --system-state            Get Docker, MCP, SSH status
  --parse-priorities        Parse current-priorities.md to JSON
  --search <term>           Search priorities for a term
  --evidence <term>         Gather evidence for a priority item
  --summary                 Quick summary statistics

Options:
  -h, --help                Show this help

Examples:
  $(basename "$0") --git-history 7
  $(basename "$0") --parse-priorities
  $(basename "$0") --search "SSH"
  $(basename "$0") --evidence "Server SSH"

EOF
    exit 0
}

# Get git history as JSON
git_history() {
    local days="${1:-30}"

    cd "$AIFRED_HOME"

    local commits=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local sha date message
            sha=$(echo "$line" | cut -d'|' -f1)
            date=$(echo "$line" | cut -d'|' -f2)
            message=$(echo "$line" | cut -d'|' -f3- | sed 's/"/\\"/g')
            commits+=("{\"sha\": \"$sha\", \"date\": \"$date\", \"message\": \"$message\"}")
        fi
    done < <(git log --since="$days days ago" --oneline --no-merges --format="%h|%ad|%s" --date=short 2>/dev/null | head -50)

    cat << EOF
{
  "period_days": $days,
  "commits": [$(IFS=,; echo "${commits[*]}")],
  "count": ${#commits[@]},
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# List recent session notes
session_notes() {
    local count="${1:-5}"

    local notes=()
    if [[ -d "$SESSION_NOTES_DIR" ]]; then
        while IFS= read -r file; do
            if [[ -n "$file" && -f "$file" ]]; then
                local name date_modified lines
                name=$(basename "$file" .md)
                date_modified=$(stat -c %Y "$file" 2>/dev/null || echo "0")
                date_modified=$(date -d "@$date_modified" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
                lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                notes+=("{\"name\": \"$name\", \"date\": \"$date_modified\", \"lines\": $lines}")
            fi
        done < <(ls -t "$SESSION_NOTES_DIR"/session-*.md 2>/dev/null | head -"$count")
    fi

    cat << EOF
{
  "session_notes": [$(IFS=,; echo "${notes[*]}")],
  "count": ${#notes[@]},
  "directory": "$SESSION_NOTES_DIR",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Get system state
system_state() {
    # Docker containers
    local docker_containers=()
    if command -v docker &>/dev/null; then
        while IFS='|' read -r name status; do
            if [[ -n "$name" ]]; then
                docker_containers+=("{\"name\": \"$name\", \"status\": \"$status\"}")
            fi
        done < <(docker ps --format "{{.Names}}|{{.Status}}" 2>/dev/null | head -20)
    fi

    # MCP servers
    local mcp_servers=()
    if command -v claude &>/dev/null; then
        while IFS= read -r server; do
            if [[ -n "$server" && "$server" != "MCP"* && "$server" != "---"* ]]; then
                local name
                name=$(echo "$server" | awk '{print $1}')
                [[ -n "$name" ]] && mcp_servers+=("\"$name\"")
            fi
        done < <(claude mcp list 2>/dev/null | tail -n +3)
    fi

    # SSH hosts
    local ssh_hosts=()
    if [[ -f "$HOME/.ssh/config" ]]; then
        while IFS= read -r host; do
            if [[ -n "$host" && "$host" != "*" ]]; then
                ssh_hosts+=("\"$host\"")
            fi
        done < <(grep "^Host " "$HOME/.ssh/config" 2>/dev/null | awk '{print $2}' | grep -v "\*")
    fi

    # Crontab entries (relevant ones)
    local cron_entries=()
    if crontab -l &>/dev/null; then
        while IFS= read -r entry; do
            if [[ -n "$entry" && "$entry" != "#"* ]]; then
                local escaped
                escaped=$(echo "$entry" | sed 's/"/\\"/g')
                cron_entries+=("\"$escaped\"")
            fi
        done < <(crontab -l 2>/dev/null | grep -v "^#" | head -10)
    fi

    cat << EOF
{
  "docker": {
    "containers": [$(IFS=,; echo "${docker_containers[*]}")],
    "count": ${#docker_containers[@]}
  },
  "mcp": {
    "servers": [$(IFS=,; echo "${mcp_servers[*]}")],
    "count": ${#mcp_servers[@]}
  },
  "ssh": {
    "hosts": [$(IFS=,; echo "${ssh_hosts[*]}")],
    "count": ${#ssh_hosts[@]}
  },
  "cron": {
    "entries": [$(IFS=,; echo "${cron_entries[*]}")],
    "count": ${#cron_entries[@]}
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Parse priorities file to JSON
parse_priorities() {
    if [[ ! -f "$PRIORITIES_FILE" ]]; then
        echo '{"error": "Priorities file not found", "path": "'"$PRIORITIES_FILE"'"}'
        exit 1
    fi

    local current_section=""
    local sections=()
    local item_count=0

    # First pass: identify sections and count items
    while IFS= read -r line; do
        # Detect h2 sections (## Section Name)
        if [[ "$line" =~ ^##[[:space:]]+(.+) ]]; then
            local section_name="${BASH_REMATCH[1]}"
            # Clean up section name - remove emojis, special chars, trim whitespace
            section_name=$(echo "$section_name" | sed 's/[^a-zA-Z0-9 _-]//g' | sed 's/  */ /g' | xargs)
            if [[ -n "$current_section" && -n "$section_name" ]]; then
                sections+=("{\"name\": \"$current_section\", \"item_count\": $item_count}")
            fi
            current_section="$section_name"
            item_count=0
        fi

        # Count checkbox items
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[([ xX?])\] ]]; then
            ((item_count++)) || true
        fi
    done < "$PRIORITIES_FILE"

    # Don't forget the last section
    if [[ -n "$current_section" ]]; then
        sections+=("{\"name\": \"$current_section\", \"item_count\": $item_count}")
    fi

    # Count totals (use || true to prevent set -e from exiting on no matches)
    local total_items completed_items pending_items unclear_items file_lines
    total_items=$(grep -c '^\s*- \[' "$PRIORITIES_FILE" 2>/dev/null) || total_items=0
    completed_items=$(grep -ci '^\s*- \[x\]' "$PRIORITIES_FILE" 2>/dev/null) || completed_items=0
    pending_items=$(grep -c '^\s*- \[ \]' "$PRIORITIES_FILE" 2>/dev/null) || pending_items=0
    unclear_items=$(grep -c '^\s*- \[\?\]' "$PRIORITIES_FILE" 2>/dev/null) || unclear_items=0
    file_lines=$(wc -l < "$PRIORITIES_FILE")

    # Build sections JSON array
    local sections_json=""
    if [[ ${#sections[@]} -gt 0 ]]; then
        sections_json=$(IFS=,; echo "${sections[*]}")
    fi

    cat << EOF
{
  "file": "$PRIORITIES_FILE",
  "sections": [$sections_json],
  "totals": {
    "total_items": $total_items,
    "completed": $completed_items,
    "pending": $pending_items,
    "unclear": $unclear_items,
    "file_lines": $file_lines
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Search priorities for a term
search_priorities() {
    local term="$1"

    if [[ ! -f "$PRIORITIES_FILE" ]]; then
        echo '{"error": "Priorities file not found", "path": "'"$PRIORITIES_FILE"'"}'
        exit 1
    fi

    local matches=()
    local line_num=0

    while IFS= read -r line; do
        ((line_num++)) || true
        if echo "$line" | grep -qi "$term" 2>/dev/null; then
            local escaped_line
            escaped_line=$(echo "$line" | sed 's/"/\\"/g' | tr -d '\n\r')
            matches+=("{\"line\": $line_num, \"content\": \"$escaped_line\"}")
        fi
    done < "$PRIORITIES_FILE"

    # Build matches JSON array
    local matches_json=""
    if [[ ${#matches[@]} -gt 0 ]]; then
        matches_json=$(IFS=,; echo "${matches[*]}")
    fi

    cat << EOF
{
  "search_term": "$term",
  "matches": [$matches_json],
  "count": ${#matches[@]},
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Gather evidence for a priority item
gather_evidence() {
    local term="$1"

    cd "$AIFRED_HOME"

    # Git commits mentioning the term
    local git_matches=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local sha date message
            sha=$(echo "$line" | cut -d'|' -f1)
            date=$(echo "$line" | cut -d'|' -f2)
            message=$(echo "$line" | cut -d'|' -f3- | sed 's/"/\\"/g')
            git_matches+=("{\"sha\": \"$sha\", \"date\": \"$date\", \"message\": \"$message\"}")
        fi
    done < <(git log --since="90 days ago" --oneline --no-merges --format="%h|%ad|%s" --date=short --grep="$term" -i 2>/dev/null | head -10)

    # Session notes mentioning the term
    local session_matches=()
    if [[ -d "$SESSION_NOTES_DIR" ]]; then
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                local name
                name=$(basename "$file" .md)
                session_matches+=("\"$name\"")
            fi
        done < <(grep -li "$term" "$SESSION_NOTES_DIR"/session-*.md 2>/dev/null | head -5)
    fi

    # Context files mentioning the term
    local context_matches=()
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            local rel_path="${file#$AIFRED_HOME/}"
            context_matches+=("\"$rel_path\"")
        fi
    done < <(grep -rli "$term" "$AIFRED_HOME/.claude/context/" 2>/dev/null | head -10)

    # Check if term looks like a service name and test
    local service_status="unknown"
    local term_lower
    term_lower=$(echo "$term" | tr '[:upper:]' '[:lower:]')

    # Docker container check
    if docker ps -a --format "{{.Names}}" 2>/dev/null | grep -qi "$term_lower"; then
        local container_status
        container_status=$(docker ps -a --filter "name=$term_lower" --format "{{.Status}}" 2>/dev/null | head -1)
        service_status="docker: $container_status"
    fi

    # SSH host check
    if grep -qi "^Host.*$term_lower" "$HOME/.ssh/config" 2>/dev/null; then
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$term_lower" "echo ok" &>/dev/null; then
            service_status="ssh: connected"
        else
            service_status="ssh: configured but not reachable"
        fi
    fi

    cat << EOF
{
  "term": "$term",
  "evidence": {
    "git_commits": {
      "matches": [$(IFS=,; echo "${git_matches[*]}")],
      "count": ${#git_matches[@]}
    },
    "session_notes": {
      "matches": [$(IFS=,; echo "${session_matches[*]}")],
      "count": ${#session_matches[@]}
    },
    "context_files": {
      "matches": [$(IFS=,; echo "${context_matches[*]}")],
      "count": ${#context_matches[@]}
    },
    "service_status": "$service_status"
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Quick summary
summary() {
    # Parse priorities for stats
    local total_items=0
    local completed_items=0
    local pending_items=0

    if [[ -f "$PRIORITIES_FILE" ]]; then
        total_items=$(grep -c "^\s*- \[" "$PRIORITIES_FILE" 2>/dev/null || echo "0")
        completed_items=$(grep -c "^\s*- \[x\]" "$PRIORITIES_FILE" 2>/dev/null || echo "0")
        pending_items=$(grep -c "^\s*- \[ \]" "$PRIORITIES_FILE" 2>/dev/null || echo "0")
    fi

    # Recent commits
    local recent_commits
    recent_commits=$(cd "$AIFRED_HOME" && git log --since="7 days ago" --oneline --no-merges 2>/dev/null | wc -l)

    # Docker containers
    local running_containers=0
    if command -v docker &>/dev/null; then
        running_containers=$(docker ps -q 2>/dev/null | wc -l)
    fi

    # Session state
    local session_status="unknown"
    if [[ -f "$SESSION_STATE_FILE" ]]; then
        session_status=$(grep -m1 "Status:" "$SESSION_STATE_FILE" 2>/dev/null | sed 's/.*Status:[[:space:]]*//' || echo "unknown")
    fi

    cat << EOF
{
  "priorities": {
    "total": $total_items,
    "completed": $completed_items,
    "pending": $pending_items
  },
  "activity": {
    "commits_7d": $recent_commits,
    "running_containers": $running_containers
  },
  "session_status": "$session_status",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Main
main() {
    local command=""
    local arg=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --git-history)
                command="git-history"
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    arg="$2"
                    shift
                fi
                shift
                ;;
            --session-notes)
                command="session-notes"
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    arg="$2"
                    shift
                fi
                shift
                ;;
            --system-state)
                command="system-state"
                shift
                ;;
            --parse-priorities)
                command="parse"
                shift
                ;;
            --search)
                command="search"
                arg="${2:-}"
                shift 2 || { echo '{"error": "Search term required"}'; exit 1; }
                ;;
            --evidence)
                command="evidence"
                arg="${2:-}"
                shift 2 || { echo '{"error": "Search term required"}'; exit 1; }
                ;;
            --summary)
                command="summary"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    case "$command" in
        git-history)
            git_history "${arg:-30}"
            ;;
        session-notes)
            session_notes "${arg:-5}"
            ;;
        system-state)
            system_state
            ;;
        parse)
            parse_priorities
            ;;
        search)
            search_priorities "$arg"
            ;;
        evidence)
            gather_evidence "$arg"
            ;;
        summary)
            summary
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"

#!/bin/bash
# Signal Helper Library for Jarvis
# Provides functions for creating command signals
#
# AUTONOMY PRINCIPLE:
# Jarvis operates autonomously by default (CLAUDE.md: "Do not wait for
# instructions — assess, decide, act"). All signal functions auto-resume
# after command execution unless explicitly paused with --pause flag.
# Pausing is the exception, not the rule.
#
# Usage:
#   source .claude/scripts/signal-helper.sh
#   signal_command "/status"              # Auto-continues (default)
#   signal_command "/status" --pause      # Waits for user (explicit)
#   send_command_signal "/compact" "Focus on code" "skill:my-skill"
#
# Or direct execution:
#   .claude/scripts/signal-helper.sh cmd "/status"
#   .claude/scripts/signal-helper.sh cmd "/status" --pause
#   .claude/scripts/signal-helper.sh send "/compact" "args" "source"

set -euo pipefail

# Configuration
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"

# Supported commands (for validation - ALLOWLIST approach for shorthand functions)
# Updated 2026-01-21: Added /statusline
SUPPORTED_COMMANDS=(
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear" "/statusline"
)

# Blocked commands (for signal_command - BLOCKLIST approach)
# These commands require interactive input or don't produce AI-useful output
# All OTHER commands are allowed by default (autonomy-first)
BLOCKED_COMMANDS=(
    "/settings"    # Opens interactive settings menu
    "/config"      # Opens interactive config menu
    "/edit"        # Opens external text editor
    "/help"        # Static help text, not actionable
    "/vim"         # Vim mode toggle, interactive
    "/model"       # Opens model selector menu
    "/theme"       # Opens theme selector
    "/permissions" # Opens permissions manager
    "/mcp"         # Opens MCP server manager
    "/plugins"     # Opens plugin manager
    "/keybindings" # Opens keybindings editor
)

# Validate command against whitelist (for shorthand functions)
validate_command() {
    local cmd="$1"
    for valid_cmd in "${SUPPORTED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid_cmd" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if command is blocked (for signal_command - blocklist approach)
is_blocked_command() {
    local cmd="$1"
    # Extract base command (before any arguments)
    local base_cmd="${cmd%% *}"
    for blocked in "${BLOCKED_COMMANDS[@]}"; do
        if [[ "$base_cmd" == "$blocked" ]]; then
            return 0  # Is blocked
        fi
    done
    return 1  # Not blocked (allowed)
}

# ============================================================================
# UNIVERSAL SIGNAL FUNCTION (Autonomy-First Design)
# ============================================================================
# signal_command - Send any slash command with autonomy as default
#
# Usage:
#   signal_command "/status"              # Auto-continues after (DEFAULT)
#   signal_command "/status" --pause      # Waits for user input (explicit)
#   signal_command "/rename" "My Session" # Command with arguments
#   signal_command "/compact" "Focus on code" --pause  # Args + pause
#
# Args:
#   $1 - Command (with or without leading /)
#   $2 - Arguments OR --pause flag
#   $3 - --pause flag (if $2 was arguments)
#
# Autonomy Principle:
#   By default, Jarvis continues working after command execution.
#   Use --pause only when you explicitly need Jarvis to wait.
# ============================================================================
signal_command() {
    local input="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"

    # Parse command and arguments
    local command=""
    local args=""
    local pause_flag="false"

    # Check if input contains a space (command + args in one string)
    if [[ "$input" == *" "* ]]; then
        command="${input%% *}"
        args="${input#* }"
    else
        command="$input"
    fi

    # Ensure command starts with /
    if [[ ! "$command" =~ ^/ ]]; then
        command="/$command"
    fi

    # Parse remaining arguments
    if [[ "$arg2" == "--pause" ]]; then
        pause_flag="true"
    elif [[ -n "$arg2" && "$arg2" != "--pause" ]]; then
        # arg2 is additional arguments
        if [[ -n "$args" ]]; then
            args="$args $arg2"
        else
            args="$arg2"
        fi
        # Check if arg3 is --pause
        if [[ "$arg3" == "--pause" ]]; then
            pause_flag="true"
        fi
    fi

    # Validate against blocklist
    if is_blocked_command "$command"; then
        echo "ERROR: '$command' is blocked from autonomous execution" >&2
        echo "Reason: Requires interactive input or doesn't produce AI-useful output" >&2
        echo "Blocked commands: ${BLOCKED_COMMANDS[*]}" >&2
        return 1
    fi

    # Determine auto_resume (autonomy-first: true unless paused)
    local auto_resume="true"
    local resume_delay="5"  # 5 seconds to ensure Claude Code is ready for input
    local resume_message="continue"

    if [[ "$pause_flag" == "true" ]]; then
        auto_resume="false"
    fi

    # Send the signal
    send_command_signal "$command" "$args" "skill:universal" "normal" "$auto_resume" "$resume_delay" "$resume_message"
}

# Create and write a command signal
# Args: command, args (optional), source, priority (optional), auto_resume (optional), resume_delay (optional), resume_message (optional)
send_command_signal() {
    local command="${1:-}"
    local args="${2:-}"
    local source="${3:-manual}"
    local priority="${4:-normal}"
    local auto_resume="${5:-false}"
    local resume_delay="${6:-3}"
    local resume_message="${7:-continue}"

    # Validate inputs
    if [[ -z "$command" ]]; then
        echo "ERROR: Command is required" >&2
        return 1
    fi

    # Ensure command starts with /
    if [[ ! "$command" =~ ^/ ]]; then
        command="/$command"
    fi

    # Validate command
    if ! validate_command "$command"; then
        echo "ERROR: Unknown command '$command'" >&2
        echo "Supported: ${SUPPORTED_COMMANDS[*]}" >&2
        return 1
    fi

    # Validate priority
    if [[ "$priority" != "immediate" && "$priority" != "normal" && "$priority" != "low" ]]; then
        echo "WARNING: Invalid priority '$priority', using 'normal'" >&2
        priority="normal"
    fi

    # Generate timestamp
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create JSON signal
    local signal_json
    signal_json=$(cat <<EOF
{
    "command": "$command",
    "args": "$args",
    "timestamp": "$timestamp",
    "source": "$source",
    "priority": "$priority",
    "auto_resume": $auto_resume,
    "resume_delay": $resume_delay,
    "resume_message": "$resume_message"
}
EOF
)

    # Write signal file
    echo "$signal_json" > "$SIGNAL_FILE"

    local resume_info=""
    if [[ "$auto_resume" == "true" ]]; then
        resume_info=" [auto-resume in ${resume_delay}s]"
    fi
    echo "Signal created: $command ${args:+"\"$args\" "}(source: $source)$resume_info"
    return 0
}

# Shorthand functions for common commands
signal_compact() {
    local instructions="${1:-}"
    local source="${2:-skill:compact}"
    send_command_signal "/compact" "$instructions" "$source"
}

signal_rename() {
    local name="${1:-}"
    local source="${2:-skill:rename}"
    if [[ -z "$name" ]]; then
        echo "ERROR: Name is required for /rename" >&2
        return 1
    fi
    send_command_signal "/rename" "$name" "$source"
}

signal_resume() {
    local session="${1:-}"
    local source="${2:-skill:resume}"
    send_command_signal "/resume" "$session" "$source"
}

signal_export() {
    local filename="${1:-}"
    local source="${2:-skill:export}"
    send_command_signal "/export" "$filename" "$source"
}

signal_status() {
    local source="${1:-skill:status}"
    send_command_signal "/status" "" "$source"
}

signal_usage() {
    local source="${1:-skill:usage}"
    send_command_signal "/usage" "" "$source"
}

signal_cost() {
    local source="${1:-skill:cost}"
    send_command_signal "/cost" "" "$source"
}

signal_stats() {
    local source="${1:-skill:stats}"
    send_command_signal "/stats" "" "$source"
}

signal_context() {
    local source="${1:-skill:context}"
    send_command_signal "/context" "" "$source"
}

signal_todos() {
    local source="${1:-skill:todos}"
    send_command_signal "/todos" "" "$source"
}

signal_hooks() {
    local source="${1:-skill:hooks}"
    send_command_signal "/hooks" "" "$source"
}

signal_bashes() {
    local source="${1:-skill:bashes}"
    send_command_signal "/bashes" "" "$source"
}

signal_doctor() {
    local source="${1:-skill:doctor}"
    send_command_signal "/doctor" "" "$source"
}

signal_review() {
    local source="${1:-skill:review}"
    send_command_signal "/review" "" "$source"
}

signal_plan() {
    local source="${1:-skill:plan}"
    send_command_signal "/plan" "" "$source"
}

signal_security_review() {
    local source="${1:-skill:security-review}"
    send_command_signal "/security-review" "" "$source"
}

signal_release_notes() {
    local source="${1:-skill:release-notes}"
    send_command_signal "/release-notes" "" "$source"
}

signal_clear() {
    local source="${1:-skill:clear}"
    send_command_signal "/clear" "" "$source" "immediate"
}

# Send any command with auto-resume enabled
# Args: command, args (optional), resume_message (optional), resume_delay (optional)
signal_with_resume() {
    local command="${1:-}"
    local args="${2:-}"
    local resume_message="${3:-continue}"
    local resume_delay="${4:-3}"
    local source="skill:auto-resume"

    if [[ -z "$command" ]]; then
        echo "ERROR: Command is required" >&2
        return 1
    fi

    send_command_signal "$command" "$args" "$source" "normal" "true" "$resume_delay" "$resume_message"
}

# Shorthand for context with auto-resume
signal_context_resume() {
    local resume_message="${1:-continue}"
    local resume_delay="${2:-3}"
    signal_with_resume "/context" "" "$resume_message" "$resume_delay"
}

# Check if watcher is running (v6 JICM watcher first, v5 legacy fallback)
is_watcher_running() {
    local v6_pid_file="$PROJECT_DIR/.claude/context/.jicm-watcher.pid"
    local v5_pid_file="$PROJECT_DIR/.claude/context/.watcher-pid"
    local pid_file=""
    if [[ -f "$v6_pid_file" ]]; then
        pid_file="$v6_pid_file"
    elif [[ -f "$v5_pid_file" ]]; then
        pid_file="$v5_pid_file"
    fi
    if [[ -n "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Get watcher status
watcher_status() {
    local v6_pid_file="$PROJECT_DIR/.claude/context/.jicm-watcher.pid"
    local v5_pid_file="$PROJECT_DIR/.claude/context/.watcher-pid"
    if [[ -f "$v6_pid_file" ]]; then
        local pid
        pid=$(cat "$v6_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "JICM v6 Watcher is RUNNING (PID: $pid)"
            # Show state from .jicm-state if available
            local state_file="$PROJECT_DIR/.claude/context/.jicm-state"
            if [[ -f "$state_file" ]]; then
                local state pct
                state=$(awk '/^state:/{print $2}' "$state_file")
                pct=$(awk '/^context_pct:/{print $2}' "$state_file")
                echo "State: ${state:-?} | Context: ${pct:-?}%"
            fi
            return 0
        fi
    fi
    if [[ -f "$v5_pid_file" ]]; then
        local pid
        pid=$(cat "$v5_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Legacy Watcher is RUNNING (PID: $pid)"
            return 0
        fi
    fi
    echo "Watcher is NOT RUNNING"
    echo "Start with: .claude/scripts/jicm-watcher.sh (v6) or launch-jarvis-tmux.sh"
    return 1
}

# List pending signal (if any)
pending_signal() {
    if [[ -f "$SIGNAL_FILE" ]]; then
        echo "Pending signal:"
        cat "$SIGNAL_FILE"
    else
        echo "No pending signal"
    fi
}

# CLI interface when run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        cmd|command)
            # Universal command signal (autonomy-first)
            shift
            signal_command "$@"
            ;;
        send)
            shift
            send_command_signal "$@"
            ;;
        compact)
            shift
            signal_compact "$@"
            ;;
        rename)
            shift
            signal_rename "$@"
            ;;
        resume)
            shift
            signal_resume "$@"
            ;;
        export)
            shift
            signal_export "$@"
            ;;
        status)
            signal_status "cli:signal-helper"
            ;;
        usage)
            signal_usage "cli:signal-helper"
            ;;
        cost)
            signal_cost "cli:signal-helper"
            ;;
        stats)
            signal_stats "cli:signal-helper"
            ;;
        context)
            signal_context "cli:signal-helper"
            ;;
        context-resume)
            shift
            signal_context_resume "$@"
            ;;
        with-resume)
            shift
            signal_with_resume "$@"
            ;;
        todos)
            signal_todos "cli:signal-helper"
            ;;
        hooks)
            signal_hooks "cli:signal-helper"
            ;;
        bashes)
            signal_bashes "cli:signal-helper"
            ;;
        doctor)
            signal_doctor "cli:signal-helper"
            ;;
        review)
            signal_review "cli:signal-helper"
            ;;
        plan)
            signal_plan "cli:signal-helper"
            ;;
        security-review)
            signal_security_review "cli:signal-helper"
            ;;
        release-notes)
            signal_release_notes "cli:signal-helper"
            ;;
        clear)
            signal_clear "cli:signal-helper"
            ;;
        watcher-status)
            watcher_status
            ;;
        context-status|ctx)
            # Read context from statusline capture (no TUI scraping needed)
            STATUSLINE_FILE="$HOME/.claude/logs/statusline-input.json"
            if [[ -f "$STATUSLINE_FILE" ]]; then
                USED=$(jq -r '.context_window.used_percentage // 0' "$STATUSLINE_FILE")
                REMAINING=$(jq -r '.context_window.remaining_percentage // 100' "$STATUSLINE_FILE")
                INPUT_TOKENS=$(jq -r '.context_window.total_input_tokens // 0' "$STATUSLINE_FILE")
                OUTPUT_TOKENS=$(jq -r '.context_window.total_output_tokens // 0' "$STATUSLINE_FILE")
                COST=$(jq -r '.cost.total_cost_usd // 0' "$STATUSLINE_FILE")
                TOTAL=$((INPUT_TOKENS + OUTPUT_TOKENS))
                echo "Context: ${USED}% used, ${REMAINING}% remaining"
                echo "Tokens: ${TOTAL} (in:${INPUT_TOKENS} out:${OUTPUT_TOKENS})"
                printf "Cost: \$%.2f\n" "$COST"
            else
                echo "ERROR: Statusline capture not found at $STATUSLINE_FILE"
                echo "Ensure jarvis-statusline.sh is configured in ~/.claude/settings.json"
            fi
            ;;
        pending)
            pending_signal
            ;;
        help|--help|-h|*)
            echo "Signal Helper - Create command signals for Jarvis watcher"
            echo ""
            echo "AUTONOMY PRINCIPLE: Jarvis auto-continues by default (--pause to opt out)"
            echo ""
            echo "Usage:"
            echo "  $0 cmd <command> [args] [--pause]    # Universal (RECOMMENDED)"
            echo "  $0 send <command> [args] [source] [priority] [auto_resume] [delay] [msg]"
            echo "  $0 <shorthand> [args]"
            echo "  $0 watcher-status"
            echo "  $0 pending"
            echo ""
            echo "Universal Command (autonomy-first):"
            echo "  cmd /status                     - Execute and auto-continue (DEFAULT)"
            echo "  cmd /status --pause             - Execute and wait for user"
            echo "  cmd \"/rename My Session\"        - Command with arguments"
            echo "  cmd /compact \"Focus on code\"    - Command with separate args"
            echo ""
            echo "Blocked commands (interactive, no autonomous execution):"
            echo "  /settings, /config, /edit, /help, /vim, /model, /theme,"
            echo "  /permissions, /mcp, /plugins, /keybindings"
            echo ""
            echo "Legacy Shorthands (still supported):"
            echo "  compact [instructions]   - Signal /compact"
            echo "  rename <name>            - Signal /rename (name required)"
            echo "  resume [session]         - Signal /resume"
            echo "  export [filename]        - Signal /export"
            echo "  status                   - Signal /status"
            echo "  usage                    - Signal /usage"
            echo "  cost                     - Signal /cost"
            echo "  stats                    - Signal /stats"
            echo "  context                  - Signal /context"
            echo "  todos                    - Signal /todos"
            echo "  hooks                    - Signal /hooks"
            echo "  bashes                   - Signal /bashes"
            echo "  doctor                   - Signal /doctor"
            echo "  review                   - Signal /review"
            echo "  plan                     - Signal /plan"
            echo "  security-review          - Signal /security-review"
            echo "  release-notes            - Signal /release-notes"
            echo "  clear                    - Signal /clear"
            echo ""
            echo "Auto-Resume Commands (legacy, prefer 'cmd' instead):"
            echo "  context-resume [msg] [delay]  - /context with auto-resume"
            echo "  with-resume <cmd> [args] [msg] [delay] - Any command with auto-resume"
            echo ""
            echo "Examples:"
            echo "  $0 cmd /status                       # Auto-continues (recommended)"
            echo "  $0 cmd /status --pause               # Waits for user"
            echo "  $0 cmd /compact \"Focus on code\"      # With arguments"
            echo "  $0 send /compact \"Focus\" skill:test  # Low-level send"
            ;;
    esac
fi

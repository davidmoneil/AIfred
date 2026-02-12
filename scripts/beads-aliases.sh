#!/usr/bin/env bash
# Beads Shell Aliases for AIfred
# Source this file in ~/.bashrc or ~/.zshrc:
#   source /path/to/aifred/scripts/beads-aliases.sh

# ========================================
# Domain Views (zero tokens)
# ========================================
alias bd-hooks='bd list --status open --label domain:hooks'
alias bd-skills='bd list --status open --label domain:skills'
alias bd-profiles='bd list --status open --label domain:profiles'
alias bd-docs='bd list --status open --label domain:documentation'
alias bd-infra='bd list --status open --label domain:infrastructure'

# ========================================
# Status Views (zero tokens)
# ========================================
alias bd-active='bd list --status in_progress'
alias bd-blocked='bd list --status blocked'
alias bd-all='bd list --status open'
alias bd-next='bd ready'
alias bd-done='bd list --status closed'

# ========================================
# Priority Views (zero tokens)
# ========================================
alias bd-critical='bd list --status open --label severity:critical'
alias bd-high='bd list --status open --label severity:high'
alias bd-urgent='bd list --label-any severity:critical,severity:high --status open'

# ========================================
# Quick Actions (zero tokens)
# ========================================
# Usage: bd-add "Task title" domain priority
# Example: bd-add "Fix session hook" hooks 1
bd-add() {
    local title="$1"
    local domain="${2:-ad-hoc}"
    local priority="${3:-2}"

    if [ -z "$title" ]; then
        echo "Usage: bd-add 'Task title' [domain] [priority 0-4]"
        echo "  Domains: hooks, skills, profiles, documentation, infrastructure"
        echo "  Priority: 0=CRITICAL, 1=HIGH, 2=MEDIUM, 3=LOW, 4=Backlog"
        return 1
    fi

    bd create "$title" -t task -p "$priority" \
        -l "domain:${domain},agent:human,source:ad-hoc" \
        --json | jq -r '"Created: \(.id) - \(.title)"'
}

# Quick claim: bd-claim <id>
bd-claim() {
    bd update "$1" --status in_progress --claim
    echo "Claimed $1"
}

# Quick close: bd-close <id> "reason"
bd-close() {
    bd close "$1" --reason "${2:-Completed}"
    echo "Closed $1"
}

# Dashboard: open bv TUI
alias bd-dash='bv'

echo "Beads aliases loaded. Try: bd-all, bd-next, bd-dash, bd-add 'Task' domain priority"

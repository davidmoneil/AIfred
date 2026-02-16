#!/usr/bin/env bash
# Beads Shell Aliases for AIfred
# Source this file in ~/.bashrc or ~/.zshrc:
#   source scripts/beads-aliases.sh

# ========================================
# Domain Views (zero tokens)
# ========================================
alias bd-infra='bd list --status open --label domain:infrastructure'
alias bd-coding='bd list --status open --label domain:coding'
alias bd-creative='bd list --status open --label domain:creative'
alias bd-research='bd list --status open --label domain:research'

# ========================================
# Project Views (zero tokens)
# ========================================
alias bd-aiprojects='bd list --status open --label project:aiprojects'
alias bd-aifred='bd list --status open --label project:aifred'
alias bd-ciso='bd list --status open --label project:ciso-expert'

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
# Example: bd-add "Fix auth bug" infrastructure 1
bd-add() {
    local title="$1"
    local domain="${2:-ad-hoc}"
    local priority="${3:-2}"
    local project="${4:-aiprojects}"

    if [ -z "$title" ]; then
        echo "Usage: bd-add 'Task title' [domain] [priority 0-4] [project]"
        echo "  Domains: infrastructure, coding, creative, research"
        echo "  Priority: 0=CRITICAL, 1=HIGH, 2=MEDIUM, 3=LOW, 4=Backlog"
        echo "  Projects: aiprojects, aifred, ciso-expert, my-ai-plugin"
        return 1
    fi

    bd create "$title" -t task -p "$priority" \
        -l "domain:${domain},project:${project},agent:human,source:ad-hoc" \
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

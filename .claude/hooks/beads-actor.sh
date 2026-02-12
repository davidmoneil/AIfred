#!/usr/bin/env bash
# Beads Actor Hook - Sets BEADS_ACTOR for Claude Code sessions
# Hook Event: SessionStart (or source in session hooks)
#
# Sets the actor identity so all bd commands within a Claude session
# are attributed to the correct session for provenance tracking.

# Build actor identity from available context
SESSION_DATE=$(date +%Y%m%d)
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Truncate session ID if too long
if [ ${#SESSION_ID} -gt 12 ]; then
    SESSION_ID="${SESSION_ID:0:12}"
fi

export BEADS_ACTOR="claude-${SESSION_DATE}-${SESSION_ID}"

# Ensure bd can find the beads directory when running from any location
AIFRED_HOME="${AIFRED_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export BEADS_WORKING_DIR="${BEADS_WORKING_DIR:-$AIFRED_HOME}"

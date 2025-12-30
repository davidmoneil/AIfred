#!/bin/bash
#
# Update Priorities from Health Check
#
# Updates the current-priorities.md file based on health check findings.
# Called by weekly-health-check.sh after generating the JSON report.
#
# Usage: ./update-priorities-health.sh <json-report-path>
#
# Configuration: Set PRIORITIES_FILE in config.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration if available
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Configuration
AIFRED_DIR="${AIFRED_DIR:-$HOME/Code/AIfred}"
PRIORITIES_FILE="${PRIORITIES_FILE:-$AIFRED_DIR/.claude/context/projects/current-priorities.md}"

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <json-report-path>"
    exit 1
fi

JSON_REPORT="$1"

if [[ ! -f "$JSON_REPORT" ]]; then
    echo "JSON report not found: $JSON_REPORT"
    exit 1
fi

if [[ ! -f "$PRIORITIES_FILE" ]]; then
    echo "Priorities file not found: $PRIORITIES_FILE"
    echo "Skipping priorities update."
    exit 0
fi

# Parse JSON report
STATUS=$(jq -r '.summary.status' "$JSON_REPORT" 2>/dev/null) || STATUS="unknown"
SCORE=$(jq -r '.summary.score' "$JSON_REPORT" 2>/dev/null) || SCORE="0"
FAILED=$(jq -r '.summary.failed' "$JSON_REPORT" 2>/dev/null) || FAILED="0"
WARNED=$(jq -r '.summary.warnings' "$JSON_REPORT" 2>/dev/null) || WARNED="0"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

echo "Updating priorities file with health check results..."
echo "  Status: $STATUS, Score: $SCORE%, Failed: $FAILED, Warnings: $WARNED"

# Update the health check section in priorities file
# This is a simple append - a more sophisticated version would update in place

# Check if health check section exists
if grep -q "## Infrastructure Health" "$PRIORITIES_FILE" 2>/dev/null; then
    echo "  Health section exists - manual update may be needed"
else
    # Append health section
    cat >> "$PRIORITIES_FILE" << EOF

## Infrastructure Health

**Last Check**: $TIMESTAMP
**Status**: $STATUS
**Score**: $SCORE%
**Issues**: $FAILED failed, $WARNED warnings

EOF
    echo "  Added health section to priorities"
fi

echo "Priorities update complete."

#!/bin/bash
#
# Update current-priorities.md with latest health check findings
# Called automatically after weekly-health-check.sh runs
#
# Usage: ./update-priorities-health.sh [json_report_path]
#

set -uo pipefail

# Configuration
PRIORITIES_FILE="$HOME/AIProjects/.claude/context/projects/current-priorities.md"
REPORTS_DIR="$HOME/logs/weekly-health"

# Find latest JSON report if not provided
if [[ -n "${1:-}" ]]; then
    JSON_REPORT="$1"
else
    JSON_REPORT=$(ls -t "$REPORTS_DIR"/health-report-*.json 2>/dev/null | head -1)
fi

if [[ ! -f "$JSON_REPORT" ]]; then
    echo "Error: No health report found"
    exit 1
fi

if [[ ! -f "$PRIORITIES_FILE" ]]; then
    echo "Error: Priorities file not found: $PRIORITIES_FILE"
    exit 1
fi

# Parse JSON report
TIMESTAMP=$(jq -r '.timestamp' "$JSON_REPORT" | cut -dT -f1)
PASSED=$(jq -r '.summary.passed' "$JSON_REPORT")
WARNINGS=$(jq -r '.summary.warnings' "$JSON_REPORT")
FAILED=$(jq -r '.summary.failed' "$JSON_REPORT")
SCORE=$(jq -r '.summary.score' "$JSON_REPORT")

echo "Updating priorities with health check from $TIMESTAMP"
echo "  Score: ${SCORE}% | Passed: $PASSED | Warnings: $WARNINGS | Failed: $FAILED"

# Build the new health section
NEW_SECTION=$(cat << 'SECTION_START'
---

## 🔴 Health Check Issues (DATE_PLACEHOLDER)

> **Source**: Weekly health check (`~/Scripts/weekly-health-check.sh`)
> **Health Score**: SCORE_PLACEHOLDER% | Passed: PASSED_PLACEHOLDER | Warnings: WARNINGS_PLACEHOLDER | Failed: FAILED_PLACEHOLDER

SECTION_START
)

# Replace placeholders
NEW_SECTION="${NEW_SECTION//DATE_PLACEHOLDER/$TIMESTAMP}"
NEW_SECTION="${NEW_SECTION//SCORE_PLACEHOLDER/$SCORE}"
NEW_SECTION="${NEW_SECTION//PASSED_PLACEHOLDER/$PASSED}"
NEW_SECTION="${NEW_SECTION//WARNINGS_PLACEHOLDER/$WARNINGS}"
NEW_SECTION="${NEW_SECTION//FAILED_PLACEHOLDER/$FAILED}"

# Extract failures
FAILURES=$(jq -r '.checks[] | select(.status == "fail") | "| **\(.check)** | \(.details // .message) | Check logs/config |"' "$JSON_REPORT" 2>/dev/null)

if [[ -n "$FAILURES" ]]; then
    NEW_SECTION+="
### Critical Failures (Immediate Action Required)

| Issue | Details | Action |
|-------|---------|--------|
$FAILURES
"
else
    NEW_SECTION+="
### ✅ No Critical Failures

All critical checks passed.
"
fi

# Extract warnings with priority classification
WARNINGS_DATA=$(jq -r '.checks[] | select(.status == "warn") | "\(.check)|\(.details // .message)"' "$JSON_REPORT" 2>/dev/null)

if [[ -n "$WARNINGS_DATA" ]]; then
    NEW_SECTION+="
### Warnings (Review This Week)

| Issue | Details | Priority |
|-------|---------|----------|"

    while IFS='|' read -r check details; do
        # Classify priority based on check name
        case "$check" in
            ssh_*|db_*|api_n8n|api_grafana|api_loki)
                priority="HIGH"
                ;;
            nfs_*|api_*|loki_*|promtail_*)
                priority="MEDIUM"
                ;;
            *)
                priority="LOW"
                ;;
        esac
        NEW_SECTION+="
| **$check** | $details | $priority |"
    done <<< "$WARNINGS_DATA"
    NEW_SECTION+="
"
fi

# Add quick fixes section
NEW_SECTION+='
### Quick Fixes

```bash
# Run health check to see current status
~/Scripts/weekly-health-check.sh

# Common fixes:
# sudo mount /mnt/synology_nas  # If NAS unmounted
# chmod 600 ~/.ssh/*            # Fix SSH permissions
# docker system prune -f        # Clean up Docker
```

---
'

# Create temp file with updated content
TEMP_FILE=$(mktemp)

# Write header
head -5 "$PRIORITIES_FILE" | sed "s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $TIMESTAMP (Health Check Auto-Update)/" > "$TEMP_FILE"

# Write new health section
echo "$NEW_SECTION" >> "$TEMP_FILE"

# Find where "## In Progress" starts and append rest of file
awk '/^## In Progress/,0' "$PRIORITIES_FILE" >> "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$PRIORITIES_FILE"

echo "Updated: $PRIORITIES_FILE"
echo "Health check findings are now at the top of priorities."

# Audit Log Management

Manage Claude Code audit logging system - configure verbosity, set sessions, view logs, and query history.

## Usage

```bash
/audit-log session "Session Name"    # Set current session name
/audit-log verbosity <level>         # Set verbosity: minimal|standard|full
/audit-log status                    # Show current config and session
/audit-log view [options]            # View/query recent logs (CLI script)
/audit-log query <pattern>           # Search logs for pattern
/audit-log enable                    # Enable logging
/audit-log disable                   # Disable logging
```

## Commands

### View Logs (CLI Script)

**Recommended**: Use the CLI script for powerful log viewing:

```bash
# Basic view - last 20 entries
~/Scripts/audit-log-query.sh

# Filter by tool
~/Scripts/audit-log-query.sh --tool Bash

# Filter by session
~/Scripts/audit-log-query.sh --session "Infrastructure"

# Today's entries only
~/Scripts/audit-log-query.sh --today

# Count only
~/Scripts/audit-log-query.sh --today --count

# JSON output
~/Scripts/audit-log-query.sh --json -n 50

# Last N entries
~/Scripts/audit-log-query.sh -n 50
```

### Set Session Name

Name the current session for better log organization:

```bash
echo "N8N Workflow Debug" > .claude/logs/.current-session
```

Or use Python:
```bash
python3 .claude/logs/audit-logger.py set-session "N8N Workflow Debug"
```

### Change Verbosity

```bash
export CLAUDE_AUDIT_VERBOSITY=full      # Complete details (default)
export CLAUDE_AUDIT_VERBOSITY=standard  # Key parameters only
export CLAUDE_AUDIT_VERBOSITY=minimal   # Type and summary only
```

### Query Logs (Manual)

```bash
# Find entries mentioning docker
grep -i "docker" .claude/logs/audit.jsonl | tail -20

# Filter with jq
cat .claude/logs/audit.jsonl | jq 'select(.tool == "Bash")'
```

### Status Check

```bash
echo "Current Session:"
cat .claude/logs/.current-session 2>/dev/null || echo "No session set"
echo ""
echo "Log File:"
ls -la .claude/logs/audit.jsonl
echo ""
echo "Total Entries:"
wc -l .claude/logs/audit.jsonl
```

## CLI Script Options

| Option | Description |
|--------|-------------|
| `-t, --tool TOOL` | Filter by tool (Bash, Read, Edit, etc.) |
| `-s, --session NAME` | Filter by session name |
| `-n, --lines N` | Show last N entries (default: 20) |
| `-d, --date DATE` | Filter by date (YYYY-MM-DD) |
| `--today` | Filter to today's entries |
| `--errors` | Show only errors |
| `-j, --json` | Raw JSON output |
| `-c, --count` | Show count only |

## Script Details

**Location**: `~/Scripts/audit-log-query.sh`
**Log File**: `.claude/logs/audit.jsonl`
**Exit Codes**:
- 0: Success
- 1: Invalid arguments
- 2: Log file not found

## Notes

- Session names are automatically slugified (spaces → hyphens, lowercase)
- All logs are in JSONL format (one JSON object per line)
- Suitable for direct ingestion into Loki/Grafana

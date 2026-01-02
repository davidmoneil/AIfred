# Hooks & Automation Status

**Configured**: 2026-01-01

## Hooks

### Status: ⚠️ Node.js Required

The following hooks are available in `.claude/hooks/` but require **Node.js** to run:

**Core Hooks** (recommended):
- ✅ `audit-logger.js` - Log all tool executions
- ✅ `session-tracker.js` - Track session lifecycle
- ✅ `session-exit-enforcer.js` - Remind about exit procedures
- ✅ `secret-scanner.js` - Prevent credential commits
- ✅ `context-reminder.js` - Prompt for documentation

**Optional Hooks**:
- `docker-health-check.js` - Verify Docker health (not applicable - no Docker)
- `memory-maintenance.js` - Track Memory MCP access (not applicable - no Memory MCP)

### To Enable Hooks

Install Node.js:
```bash
# Using Homebrew (if available)
brew install node

# Or download from: https://nodejs.org/
```

Verify after installation:
```bash
node -v
```

Hooks will activate automatically when Node.js is installed.

## Automation Scripts

### Available Scripts

Located in `scripts/`:

1. **weekly-context-analysis.sh** - Analyzes context usage, archives logs
   - Status: ✅ Ready (macOS compatible)
   - Note: Ollama features require Ollama installation

2. **weekly-health-check.sh** - Infrastructure health validation
   - Status: ⚠️ Partial (Docker checks will be skipped)
   - Checks: Disk, network, processes, backups

3. **weekly-docker-restart.sh** - Docker container restarts
   - Status: ❌ Not applicable (Docker not installed)

4. **update-priorities-health.sh** - Update priority documentation
   - Status: ✅ Ready

### Configuration

**Config file**: `scripts/config.sh`
- Customized for Nathaniels-MacBook-Air.local
- Docker settings disabled
- Ready for Ollama integration (when installed)

## Scheduled Jobs

### Status: Not Configured

With Full Automation enabled, you can schedule scripts using **macOS launchd**:

Example (weekly context analysis):
```bash
# Create ~/Library/LaunchAgents/com.aifred.weekly-analysis.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aifred.weekly-analysis</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/aircannon/Documents/Jarvis/scripts/weekly-context-analysis.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>6</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

Load with: `launchctl load ~/Library/LaunchAgents/com.aifred.weekly-analysis.plist`

## Next Steps

1. **Install Node.js** to enable hooks
2. **Install Ollama** (optional) for context summarization features
3. **Configure launchd** for automated script execution
4. **Add Docker** (optional) for full infrastructure features

---

*Configured during AIfred setup Phase 5*

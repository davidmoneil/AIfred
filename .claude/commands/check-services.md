---
description: Manual health check with issue detection for registered services
argument-hint: [service|group]
skill: infrastructure-ops
allowed-tools:
  - Bash(docker:*)
  - Bash(curl:*)
  - Read
  - Glob
---

# Check Services Command

**Slash Command**: `/check-services [service|group]`
**Purpose**: Manual health check with issue detection for registered services
**Created**: 2026-01-19

## Usage

```bash
# Check all registered services
/check-services

# Check a specific service
/check-services voice-character-api

# Check a service group
/check-services --group voice-stack
```

## What It Does

1. Reads services from `.claude/context/registries/service-registry.yaml`
2. Calls each service's health endpoint
3. Parses responses for health status and dependency health
4. Writes any issues to `.claude/context/registries/detected-issues.yaml`
5. Reports results with severity-based priority mapping

## Output Example

```
🔍 Service Health Check Results

✅ HEALTHY (4 services)
  • Chatterbox TTS - running (Up 3 days)
  • Whisper Transcribe - running (Up 3 days)
  • n8n - healthy (HTTP 200)
  • Grafana - healthy (HTTP 200)

🚨 ISSUES (2 services)
  🟠 [HIGH] Voice Character System API
     Error: Connection refused on port 8200
     Action: Start the API server: cd ~/Code/voice-character-system && npm start

  🟡 [MEDIUM] ElevenLabs API
     Error: Unhealthy dependency detected
     Action: Check ElevenLabs API key validity

Issues written to: .claude/context/registries/detected-issues.yaml
```

## Priority Mapping

| Condition | Severity | Claude Priority |
|-----------|----------|-----------------|
| Critical service down | critical | `[X] CRITICAL` |
| Non-critical service down | high | `[!] HIGH` |
| Dependency unhealthy | medium | `[~] MEDIUM` |
| Warning condition | low | `[-] LOW` |

## Implementation

<implementation>
**Option A: Quick Docker Check** (new, lightweight)
```bash
~/Scripts/check-all-services.sh $ARGS
```
- Checks all running Docker containers
- Fast JSON/quiet output available
- Use for quick status overview

**Option B: Full Service Detection** (original, comprehensive)
```bash
~/Scripts/detect-service-issues.sh $ARGS
```
- Reads from service registry
- Writes issues to detected-issues.yaml
- Use for detailed diagnostics

Where `$ARGS` is:
- Empty for all services
- `--service <name>` for specific service
- `--group <name>` for service group

After running, read and summarize the results from:
- `detected-issues.yaml` for any issues found
- Script output for immediate feedback

### Service Groups Available

| Group | Services |
|-------|----------|
| `voice-stack` | voice-character-api, chatterbox-tts, whisper-transcribe, elevenlabs-api |
| `monitoring-stack` | grafana, loki, prometheus |
| `core-infrastructure` | n8n, caddy, grafana, loki |

### On Issues Found

1. Display issues with severity and suggested actions
2. Offer to add critical/high issues to current-priorities.md
3. Suggest relevant documentation links

### Example Integration with Priorities

If issues are found, offer:

```
Would you like me to add these issues to your current priorities?
- [!] HIGH: Voice Character API down → "Fix voice-character-api service"
- [~] MEDIUM: ElevenLabs dependency → "Troubleshoot ElevenLabs connection"
```
</implementation>

## Related Files

- `Scripts/detect-service-issues.sh` - The underlying detection script
- `.claude/context/registries/service-registry.yaml` - Service definitions
- `.claude/context/registries/detected-issues.yaml` - Detected issues
- `.claude/context/patterns/health-endpoint-pattern.md` - Health endpoint standard

## Automation

This check runs automatically:
- Weekly via `Scripts/weekly-health-check.sh`
- Issues surface on session start via `session-start.js` hook

---

*Part of the Unified Service Monitoring System*

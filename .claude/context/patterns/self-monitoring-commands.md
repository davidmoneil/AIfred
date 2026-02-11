# Self-Monitoring Commands Pattern

**Purpose**: Clarify the distinction between Claude Code's self-monitoring commands and how Jarvis uses them for autonomous operation.

**Created**: 2026-01-21
**Related**: PR-12.11 (Auto-Resume Enhancement)

---

## Critical Distinction: /usage vs /context

These two commands serve DIFFERENT purposes and should NOT be confused:

| Aspect | `/usage` | `/context` |
|--------|----------|------------|
| **Shows** | Token BUDGET (quota) | Context WINDOW (conversation) |
| **Scope** | Session/daily/weekly limits | Current conversation only |
| **Percentage** | % of allowed quota used | % of max context filled |
| **Resets** | Time-based (daily/weekly) | On /clear or new conversation |
| **Use Case** | "How much can I still use today?" | "How much context space is left?" |

### /usage Output Example
```
Current session
█████████                                          18% used
Resets 1pm (America/Denver)

Current week (all models)
██████▌                                            13% used
Resets Jan 27 at 1pm (America/Denver)
```

### /context Output Example
```
Context Window Usage:
├── System prompts:     15,234 tokens (7.6%)
├── CLAUDE.md:           2,847 tokens (1.4%)
├── Conversation:       85,432 tokens (42.7%)
├── MCP tools:          12,456 tokens (6.2%)
└── Available:          84,031 tokens (42.1%)

Total: 115,969 / 200,000 tokens (58.0%)
```

---

## Self-Monitoring Commands Overview

| Command | Purpose | Jarvis Use |
|---------|---------|------------|
| `/context` | Context window breakdown | JICM threshold monitoring |
| `/usage` | Token budget status | Session budget tracking |
| `/stats` | Session statistics | Performance analytics |
| `/cost` | API cost information | Cost tracking |
| `/status` | Session/project status | State awareness |
| `/doctor` | Installation health | Diagnostics |
| `/bashes` | Running processes | Process monitoring |

---

## Jarvis Self-Monitoring Patterns

### Pattern 1: Context Window Monitoring (JICM)

**Purpose**: Monitor context window to trigger JICM compression before auto-compact.

**Data Source**: JICM v6 watcher reads token count from statusline capture.
**File**: `.claude/context/.jicm-state`

```yaml
# Example JICM v6 state
state: WATCHING
timestamp: 2026-02-11T12:00:00Z
context_pct: 42
context_tokens: 84000
threshold: 55
compressions: 3
errors: 0
pid: 12345
version: 6.1.0
```

**Workflow**:
1. JICM v6 watcher polls statusline capture for token count
2. Calculates percentage of max context
3. At threshold (55%), triggers stop-and-wait compression
4. States: WATCHING → HALTING → COMPRESSING → CLEARING → RESTORING

### Pattern 2: Budget Monitoring (via /usage)

**Purpose**: Track session/daily token budget consumption.

**Autonomous Flow**:
```
1. Jarvis sends: .claude/scripts/signal-helper.sh with-resume /usage "" "continue" 3
2. Watcher executes /usage
3. Claude Code displays budget bars
4. After 3s, watcher sends "continue"
5. Jarvis receives system-reminder with /usage info
6. Jarvis can log/track/alert based on budget
```

### Pattern 3: Combined Health Check

**Purpose**: Full self-assessment combining context + budget.

```
1. Check context window (.jicm-state or /context)
2. Check budget (/usage with auto-resume)
3. Aggregate into health report
4. Store in .claude/logs/health-check.json
5. Continue with work
```

---

## Auto-Resume for Self-Monitoring

### Why Auto-Resume Matters

Fire-and-forget commands don't return data to Jarvis. With auto-resume:
1. Command executes and displays output
2. Watcher waits (configurable delay)
3. Watcher sends continuation message
4. Jarvis resumes with access to command output in system-reminder

### Using Auto-Resume

```bash
# Check context with auto-resume
.claude/scripts/signal-helper.sh with-resume /context "" "continue" 3

# Check usage with auto-resume
.claude/scripts/signal-helper.sh with-resume /usage "" "proceed" 3

# Check stats with auto-resume
.claude/scripts/signal-helper.sh with-resume /stats "" "next" 3
```

### Auto-Resume Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| command | The /slash-command to execute | required |
| args | Arguments for the command | "" |
| resume_message | Message sent after delay | "continue" |
| resume_delay | Seconds to wait | 3 |

---

## Best Practices

1. **Use /context for JICM decisions** — It shows what's consuming context
2. **Use /usage for budget awareness** — It shows quota consumption
3. **Don't conflate percentages** — 50% context ≠ 50% budget
4. **Prefer .jicm-state for context** — It's already tracked by JICM v6 watcher
5. **Use auto-resume for workflows** — Fire-and-forget doesn't return data
6. **Log health checks** — Store in `.claude/logs/` for analytics

---

*Self-Monitoring Commands Pattern v1.0*
*Created: 2026-01-21*

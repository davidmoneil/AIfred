# Brainstorm: Setup Regression Testing

*Created: 2026-01-05*
*Status: Brainstorm / Idea*
*Related PRs: PR-4 (Setup Preflight), PR-10 (Setup Upgrade)*

---

## Problem Statement

Jarvis's `/setup` with preflight validation establishes a known-good state. But as tools, MCPs, plugins, and configurations are added over time, how do we ensure the setup remains valid?

### The Drift Problem

```
Day 0:  /setup runs → Preflight PASS → Ready state ✓
Day 30: New MCP installed → Preflight still valid? Unknown
Day 60: Plugin added, hook modified → Preflight still valid? Unknown
Day 90: User asks "why isn't X working?" → Setup regressed silently
```

Without periodic re-validation, Jarvis can drift from its "known-good" state without detection.

---

## Key Questions

### 1. When Should Regression Testing Run?

| Trigger | Pros | Cons |
|---------|------|------|
| **Session start** | Catches issues early | Adds latency to every session |
| **After tool installation** | Immediate feedback | Requires hook integration |
| **Periodic (daily/weekly)** | Non-blocking | May miss issues between checks |
| **On-demand (`/health-check`)** | User-controlled | Relies on user remembering |
| **Pre-commit hook** | Catches config changes | Only for Jarvis repo changes |

### 2. What Should Be Re-Validated?

**Preflight Checks (from PR-4b)**:
- Workspace existence and git status
- AIfred baseline separation
- Settings.json and hooks present
- Git/Docker availability

**Extended Checks (post-tool-addition)**:
- MCP servers configured and reachable
- Plugins loaded without errors
- Hooks syntactically valid (already have this)
- No path conflicts in `paths-registry.yaml`
- Tool inventory completeness

### 3. How Deep Should Validation Go?

| Level | What's Checked | Cost |
|-------|----------------|------|
| **Shallow** | Files exist, syntax valid | Fast (~1s) |
| **Medium** | Services reachable, configs parseable | Moderate (~5s) |
| **Deep** | Smoke tests per tool, end-to-end flows | Slow (~30s+) |

---

## Proposed Solution: Tiered Validation

### Tier 1: Quick Check (Session Start)
- **When**: Every session start (automated or manual trigger)
- **What**: Subset of preflight checks
- **Time**: < 2 seconds
- **Output**: PASS/WARN/FAIL status line

Checks:
- [ ] Jarvis workspace exists and is git repo
- [ ] AIfred baseline path different from Jarvis
- [ ] Hooks directory has JS files
- [ ] No syntax errors in critical configs

### Tier 2: Health Check (On-Demand)
- **When**: User runs `/health-check` or after tool installation
- **What**: Full preflight + tool validation
- **Time**: 5-10 seconds
- **Output**: Structured report with severity ratings

Checks:
- [ ] All Tier 1 checks
- [ ] MCP servers respond to ping/status
- [ ] Plugins load without errors
- [ ] All hooks pass syntax check
- [ ] Path registry entries are valid paths
- [ ] No known non-conformant artifacts outside workspace

### Tier 3: Deep Validation (Periodic/Release)
- **When**: Before version bump, weekly cron, or explicit request
- **What**: Full health check + smoke tests
- **Time**: 30-60 seconds
- **Output**: Detailed report with recommendations

Checks:
- [ ] All Tier 2 checks
- [ ] Each enabled MCP can perform basic operation
- [ ] Sample skill invocation works
- [ ] Benchmark demo can start (not full run)
- [ ] Audit log is being written

---

## Integration with Existing Components

### Session Start Checklist
Extend `session-start-checklist.md` with optional Tier 1 check:

```markdown
### 5. Quick Validation (Optional but Recommended)
Run a quick setup validation to ensure no regression:
- If preflight passes silently, continue
- If WARN or FAIL, investigate before proceeding
```

### Health Check Command
Extend `/health-check` to include setup regression:

```markdown
## Health Check Output

### System Health
- Docker: ✅ Running
- Git: ✅ v2.50.1

### Setup Regression
- Workspace: ✅ Valid
- Hooks: ✅ 11 hooks, all valid
- MCPs: ⚠️ memory-mcp not responding (expected if disabled)
- Plugins: ✅ 3 plugins loaded

### Recommendation
[~] MEDIUM: Memory MCP appears disabled. Enable if needed for this session.
```

### Post-Tool-Installation Hook
Create a "tool-added" hook or convention:

```javascript
// After MCP installation, prompt for validation
// "New MCP 'context7' installed. Run /health-check to validate."
```

---

## Automation Options

### Option A: Session-Start Auto-Check (Lightweight)
Add to session-tracker.js:
- Run Tier 1 checks on session start
- Output single-line status: `[Setup: ✓ Valid]` or `[Setup: ⚠ Check /health-check]`
- Non-blocking (just informational)

### Option B: Tool-Installation Trigger
Detect when tools are added and auto-run Tier 2:
- Hook on MCP config changes
- Hook on plugin installation
- Prompt user with results

### Option C: Scheduled Background Check
- Weekly Tier 3 validation (via Jeeves when implemented)
- Store results in `.claude/reports/health-YYYY-MM-DD.json`
- Surface issues at next session start

---

## Implementation Considerations

### State Tracking
Need to track "expected state" to detect regression:

```yaml
# .claude/config/expected-state.yaml
last_validated: "2026-01-05T10:30:00Z"
validation_tier: 2
result: PASS
expected_components:
  mcps:
    - memory
    - fetch
    - filesystem
  plugins:
    - feature-dev
    - hookify
  hooks: 11
```

Compare current state vs expected state to detect drift.

### False Positives
- On-Demand MCPs may not be enabled → shouldn't fail
- Development-in-progress may have temporary invalid states
- Need "known exceptions" list

### Reporting
- Machine-readable (JSON) for automation
- Human-readable (Markdown) for review
- Severity-coded per existing standard

---

## PR Placement Options

### Option 1: Extend PR-4c (Readiness Report)
- **What**: Add regression checking to the readiness report
- **When**: Now (immediate)
- **Scope**: Minimal—just extend existing work

### Option 2: Part of PR-10 (Setup Upgrade)
- **What**: Full regression testing framework after tools exist
- **When**: After tooling baseline (PR-5→8)
- **Scope**: Comprehensive—knows about all tools

### Option 3: New PR-10b (Setup Regression Testing)
- **What**: Dedicated sub-PR for regression testing
- **When**: After PR-10
- **Scope**: Focused but thorough

### Recommendation

**Two-phase approach**:
1. **PR-4c**: Add Tier 1 (quick check) to session start pattern
2. **PR-10b**: Full regression testing framework after tools exist

Rationale:
- Can't fully validate tools that don't exist yet (PR-5→8)
- But can establish the pattern and basic checks now
- PR-10 is about "Setup Upgrade" so regression fits naturally

---

## Related Patterns

- **session-start-checklist.md** — Already defines session start steps
- **00-preflight.md** — Existing preflight checks to extend
- **mcp-loading-strategy.md** — Defines which MCPs should be enabled
- **tool-conformity-pattern.md** — Complementary pattern for tool behavior

---

## Questions for Future Resolution

1. How much latency is acceptable at session start for validation?
2. Should validation failures block session start or just warn?
3. How to handle "expected disabled" components (On-Demand MCPs)?
4. Should Jeeves run periodic validation when implemented?
5. What's the right cadence for Tier 3 deep validation?

---

## Action Items

- [ ] Decide on Tier 1 integration with session start (PR-4c)
- [ ] Design expected-state tracking schema
- [ ] Extend /health-check with setup regression output
- [ ] Document "known exceptions" handling
- [ ] Plan Tier 2/3 implementation for PR-10b

---

*Brainstorm: Setup Regression Testing — Awaiting Prioritization*

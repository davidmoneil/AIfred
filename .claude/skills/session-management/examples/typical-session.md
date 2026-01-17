# Example: Typical Development Session

A walkthrough of a typical Claude Code development session using the session-management skill.

---

## Scenario

You're implementing a new feature over multiple sessions. Here's how to manage the session lifecycle effectively.

---

## Session 1: Starting the Feature

### Start

```
[Claude Code starts]
[session-start.sh fires AC-01 Self-Launch Protocol]

Phase A - Greeting:
"Good morning, sir."

Phase B - System Review:
- Session state: idle
- Priorities: "Implement PR-5 Core Tooling Baseline"
- Branch: Project_Aion (0 uncommitted changes)

Phase C - Briefing:
"System review complete. Last session completed baseline sync.
AIfred baseline: 2 commits ahead → suggesting /sync-aifred-baseline"
```

### During

```
User: "Let's sync the baseline first"

/sync-aifred-baseline
→ Analyzes upstream changes
→ Generates sync report
→ Classifies: 2 ADOPT, 3 ADAPT, 1 DEFER

User: "Port the ADOPT items"

[Work on porting hooks and agents...]

[doc-sync-trigger.js tracks changes]
```

### End

```
User: "Let's end the session"

/end-session
→ Updates session-state.md:
  Status: idle
  What was done: Ported baseline hooks from af66364
  Next steps: Continue with PR-5 Core Tooling
→ Commits and pushes changes
→ session-stop.js sends notification: "Claude Code Complete"
```

---

## Session 2: Continuing the Feature

### Start

```
[Claude Code starts]
[session-start.sh fires AC-01 Self-Launch Protocol]

"Good afternoon, sir.

System review complete.
Status: 'Ported baseline hooks'
Next step: PR-5 Core Tooling

Continuing with PR-5 implementation."

[Jarvis proceeds autonomously with suggested work]
```

### During (Needs MCP Restart)

```
User: "I need to check the memory graph"

[Memory MCP is On-Demand, currently disabled]

/checkpoint
→ Saves to session-state.md:
  - Current task: PR-5 research phase
  - Pending: Identify default MCPs to enable
→ Provides: "Enable memory MCP in Docker Desktop, then restart"

[Exit Claude Code]
[Enable Memory MCP]
[Restart Claude Code]

[session-start.sh detects checkpoint, auto-resumes]

"Good afternoon, sir. Resuming from checkpoint.

CHECKPOINT LOADED
- Current task: PR-5 research phase
- Pending: Identify default MCPs to enable

Continuing with MCP identification..."

[No user prompt needed - auto-resume]
```

### End

```
/end-session
→ Updates session-state.md
→ Commits and pushes
```

---

## Session 3: Completing the Feature

### Start

```
[Context auto-loaded]
User: "Continue PR-5"
```

### During (Doc Sync Triggered)

```
[After modifying several files...]

[doc-sync-trigger.js]:
"Documentation Sync Suggested
5 significant code changes in the last 24 hours:
  • .claude/hooks/session-start.js
  • .claude/agents/memory-bank-synchronizer.md
  • ...
Consider running: /agent memory-bank-synchronizer"

/agent memory-bank-synchronizer --check-only
→ Report: 2 docs need updates
→ hooks/README.md: hook count outdated
→ CLAUDE.md: missing new sections

/agent memory-bank-synchronizer
→ Updates technical content
→ Preserves user decisions
→ Reports changes made
```

### End (Feature Complete)

```
[Update VERSION, CHANGELOG.md]

/end-session
→ Updates session-state.md
→ Creates release commit
→ Tags v1.4.0
→ Pushes to origin/Project_Aion
```

---

## Key Takeaways

1. **AC-01 Self-Launch** - Three-phase startup (greeting, review, briefing)
2. **Autonomous initiation** - Jarvis suggests next work, never just waits
3. **Checkpoint auto-resume** - MCP restarts continue seamlessly
4. **Persona consistency** - Jarvis identity adopted automatically
5. **Context management** - JICM tracks and manages context budget
6. **Proper exit ensures continuity** - Next session picks up seamlessly
7. **Guardrails protect workspace** - Can't accidentally modify AIfred baseline

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
[session-start.js auto-loads context]

Context injected:
- Session state: idle
- Priorities: "Implement PR-5 Core Tooling Baseline"
- Branch: Project_Aion (0 uncommitted changes)
- AIfred baseline: 2 commits ahead → run /sync-aifred-baseline
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
[session-start.js auto-loads context]

Context injected:
- Session state: "Ported baseline hooks, next: PR-5 Core Tooling"
- Branch: Project_Aion (0 uncommitted changes)
- AIfred baseline: up to date

User: "Let's continue with PR-5"
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

[session-start.js loads context including checkpoint info]

User: "Continue from checkpoint"
→ Resumes PR-5 work
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

1. **Context auto-loads** - No manual file reading needed at start
2. **Baseline sync integrated** - Upstream changes detected automatically
3. **Checkpoint preserves state** - MCP restarts don't lose context
4. **Doc sync keeps things fresh** - Code changes trigger sync suggestions
5. **Proper exit ensures continuity** - Next session picks up seamlessly
6. **Guardrails protect workspace** - Can't accidentally modify AIfred baseline

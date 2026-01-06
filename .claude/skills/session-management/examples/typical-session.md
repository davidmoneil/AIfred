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
- Priorities: "Implement user authentication"
- Branch: main (0 uncommitted changes)
```

### During

```
User: "Build a full authentication system with OAuth and JWT"

[orchestration-detector.js scores this as 9+ (complex)]
[Hook injects: "This looks like a complex task. Invoking /orchestration:plan"]

/orchestration:plan "authentication system with OAuth and JWT"
→ Creates .claude/orchestration/2026-01-05-auth-system.yaml
→ Phase 1: Foundation (4 tasks)
→ Phase 2: OAuth Integration (3 tasks)
→ Phase 3: JWT Implementation (3 tasks)
→ Phase 4: Testing (2 tasks)

[Work on Phase 1 tasks...]

/orchestration:commit T1.1 "Set up auth middleware"
→ Creates commit linked to task T1.1
→ Marks T1.1 complete
```

### End

```
User: "Let's end the session"

[Update session-state.md]
Status: idle
What was done: Completed Phase 1 of auth system (T1.1-T1.4)
Next steps: Begin Phase 2 OAuth integration
Active orchestration: auth-system (25% complete)

git add . && git commit -m "Phase 1 auth foundation" && git push

[session-stop.js sends notification: "Claude Code Complete"]
```

---

## Session 2: Continuing the Feature

### Start

```
[Claude Code starts]
[session-start.js auto-loads context]

Context injected:
- Session state: "Completed Phase 1, next: Phase 2 OAuth"
- Active orchestration: auth-system (25%)
- Branch: main (0 uncommitted changes)

User: "Let's continue"

[orchestration-detector.js detects resume intent]
[Suggests: /orchestration:resume]

/orchestration:resume
→ Loads auth-system orchestration
→ Shows: Phase 2 ready, T2.1 "Configure OAuth provider" is next
→ Creates TodoWrite entries for Phase 2 tasks
```

### During (Needs MCP Restart)

```
User: "I need to check the n8n workflows"

[n8n-MCP is On-Demand, currently disabled]

/checkpoint
→ Saves to session-state.md:
  - Current task: T2.2 OAuth callback handler
  - Pending: T2.3 remaining
→ Provides: "Enable n8n-MCP in settings.local.json, then restart"

[Exit Claude Code]
[Enable n8n-MCP]
[Restart Claude Code]

[session-start.js loads context including checkpoint info]

User: "Continue from checkpoint"
→ Resumes T2.2 work
```

### End

```
/update-priorities complete "Phase 2 OAuth Integration"
→ Updates current-priorities.md
→ Shows: "Marked complete. Follow-up: Phase 3 JWT"

[Update session-state.md]
[Commit and push]
```

---

## Session 3: Completing the Feature

### Start

```
[Context auto-loaded]
/orchestration:resume
→ Phase 3 ready (JWT Implementation)
```

### During (Doc Sync Triggered)

```
[After modifying several files...]

[doc-sync-trigger.js]:
"Documentation Sync Suggested
5 significant code changes in the last 24 hours:
  • .claude/commands/auth-verify.md
  • src/middleware/jwt.ts
  • ...
Consider running: /agent memory-bank-synchronizer"

/agent memory-bank-synchronizer --check-only
→ Report: 2 docs need updates
→ hooks/README.md: hook count outdated
→ systems/auth.md: code examples stale

/agent memory-bank-synchronizer
→ Updates technical content
→ Preserves user decisions
→ Reports changes made
```

### End (Feature Complete)

```
/orchestration:status
→ auth-system: 100% complete
→ All 12 tasks done

/update-priorities complete "Implement user authentication"

[Full session exit procedure]
[Orchestration archived to .claude/orchestration/archive/]
```

---

## Key Takeaways

1. **Context auto-loads** - No manual file reading needed at start
2. **Complex tasks auto-detected** - Orchestration suggested for multi-phase work
3. **Checkpoint preserves state** - MCP restarts don't lose context
4. **Doc sync keeps things fresh** - Code changes trigger sync suggestions
5. **Proper exit ensures continuity** - Next session picks up seamlessly

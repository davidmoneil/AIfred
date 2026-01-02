# Session Exit Procedure

Standard workflow for ending Claude Code sessions cleanly.

---

## Quick Checklist

```markdown
- [ ] Update session-state.md (status, summary, next pickup)
- [ ] Review session todos (complete or document pending)
- [ ] Update current-priorities.md with completed items
- [ ] Commit any uncommitted changes
- [ ] Push to GitHub if applicable
- [ ] **Disable On-Demand MCPs** (auto-revert to default off)
- [ ] Note any blockers or follow-ups
```

---

## When to Use

Run `/end-session` at the end of any significant session, especially when:
- Multiple tasks were completed
- Important discoveries were made
- Configuration changes were implemented
- Complex problem-solving occurred

For trivial sessions (quick lookups), this may be overkill.

---

## Detailed Steps

### 1. Update Session State

**File**: `.claude/context/session-state.md`

Set status:
- 🟢 Idle - Work complete, nothing pending
- 🟡 Active - Will continue later
- 🔴 Blocked - Waiting on something

Update "What Was Accomplished" and "Next Session Pickup" sections.

### 2. Review Todos

Check session todos:
- ✅ Mark completed tasks
- 📝 Move incomplete to current-priorities.md
- 🚫 Remove irrelevant items

### 3. Update Priorities

**File**: `.claude/context/projects/current-priorities.md`

Add completed items to "Completed" section with date.

### 4. Git Status Check

```bash
git status
git add -A  # if changes
git commit -m "Session: [brief description]"
git push origin main  # if applicable
```

### 5. Disable On-Demand MCPs

If any On-Demand MCPs were enabled for this session, disable them:

```bash
claude mcp list        # Check what's enabled
claude mcp remove <mcp-name>  # Disable each On-Demand MCP
```

**On-Demand MCPs** (should be OFF by default):
- n8n-MCP, GitHub MCP, SSH MCP, Prometheus MCP, Grafana MCP

See @.claude/context/patterns/mcp-loading-strategy.md for details.

### 6. Document Follow-ups

Add any pending work to appropriate priority section.

---

## Time Estimate

- Simple session: 2-3 minutes
- Complex session: 5-10 minutes

---

## Automation

The `/end-session` command automates most of this process.

---

*AIfred Session Management*

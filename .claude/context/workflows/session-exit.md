# Session Exit Procedure

Standard workflow for ending Claude Code sessions cleanly.

---

## Quick Checklist

```markdown
## MANDATORY GATE (if milestone work done)
- [ ] Milestone Documentation Gate PASSED
  - [ ] Planning doc checkboxes updated (roadmap.md)
  - [ ] Chronicle entry written (if milestone completed)
  - [ ] Session state reflects milestone work

## STANDARD CHECKS
- [ ] Review planning-tracker.yaml (mandatory docs verified)
- [ ] Update session-state.md (status, summary, next pickup)
- [ ] Capture MCP state (current + predicted for next session)
- [ ] Review session todos (complete or document pending)
- [ ] Update current-priorities.md with completed items
- [ ] Commit any uncommitted changes
- [ ] Push to GitHub if applicable
- [ ] Disable On-Demand MCPs (Tier 3, high-token)
- [ ] Note any blockers or follow-ups
```

> **Gate Reference**: `.claude/review-criteria/milestone-completion-gate.yaml`
> **Tracker Reference**: `.claude/planning-tracker.yaml`

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

### 2. Capture MCP State (PR-8.5 Protocol)

**Purpose**: Enable intelligent MCP suggestions at next session start.

```bash
# 1. Capture current state
.claude/scripts/suggest-mcps.sh --capture

# 2. Get suggestions for next session (based on "Next Step")
.claude/scripts/suggest-mcps.sh
```

**Update session-state.md** with MCP state:
```markdown
### MCP State
- **Active**: memory, filesystem, fetch, git (Tier 1)
- **Enabled Tier 2**: github, context7 (if applicable)
- **Next Session Prediction**: brave-search, perplexity (based on Next Step)
```

**Keyword-to-MCP Mapping**: The suggest script analyzes "Next Step" for keywords:
- PR/github/issue → `github`
- research/search → `brave-search`, `perplexity`, `gptresearcher`
- documentation/docs → `context7`, `wikipedia`
- browser/automation → `playwright`

See @.claude/context/patterns/mcp-design-patterns.md for full mapping.

### 3. Review Todos

Check session todos:
- ✅ Mark completed tasks
- 📝 Move incomplete to current-priorities.md
- 🚫 Remove irrelevant items

### 4. Update Priorities

**File**: `.claude/context/current-priorities.md`

Add completed items to "Completed" section with date.

### 5. Git Status Check

```bash
git status
git add -A  # if changes
git commit -m "Session: [brief description]"
git push origin main  # if applicable
```

### 6. Disable On-Demand MCPs (Tier 2/3)

If task-scoped MCPs were enabled, disable to reset for next session:

```bash
# Check current state
.claude/scripts/list-mcp-status.sh

# Disable task-specific MCPs
.claude/scripts/disable-mcps.sh github context7 sequential-thinking
```

**Tier 3 MCPs** (always disable after use):
- `playwright` — browser automation (~6K tokens)
- `lotus-wisdom` — contemplative reasoning (~2K tokens)

**Tier 2 MCPs** (disable if not needed for next step):
- `github`, `context7`, `sequential-thinking`, `brave-search`, `arxiv`
- `datetime`, `wikipedia`, `chroma`, `desktop-commander`
- `perplexity`, `gptresearcher`

See @.claude/context/patterns/mcp-loading-strategy.md for tier definitions.

### 7. Document Follow-ups

Add any pending work to appropriate priority section.

### 8. Checklist Hygiene

**File**: `.claude/planning-tracker.yaml`

Review planning documents for stale checkboxes and exit criteria.

```bash
# 1. Read the planning tracker
cat .claude/planning-tracker.yaml
```

**For documents in `always_review`**:
- Update session-state.md with current status
- Update current-priorities.md with completed tasks

**For documents matching current work scope**:
- Check for unchecked items that may now be complete
- Update checkboxes as appropriate
- Note any deviations in progress docs

**After review**:
- Update `last_updated` in planning-tracker.yaml

This step prevents checkbox drift — where tasks are completed but docs remain stale.

---

## Time Estimate

- Simple session: 2-3 minutes
- Complex session: 5-10 minutes

---

## Automation

The `/end-session` command automates most of this process.

---

## MCP Protocol Integration (PR-8.5)

This exit procedure integrates with the MCP Initialization Protocol:

1. **Session End** → Capture MCP state → Update session-state.md
2. **Session Start** → session-start.sh reads "Next Step" → Suggests MCPs
3. **User Decision** → Enable suggested MCPs → /clear to apply

The protocol ensures context-efficient MCP loading across session boundaries.

See @.claude/context/patterns/mcp-loading-strategy.md for full protocol.

---

*Session Exit Procedure v2.2 — Updated 2026-01-23 (Milestone Documentation Gate enforcement added)*

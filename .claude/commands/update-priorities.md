---
argument-hint: [review|add|complete|plan]
description: Manage and validate current priorities
skill: session-management
allowed-tools:
  - Bash(scripts/update-priorities.sh:*)
  - Bash(git:*)
  - Read
  - Edit
  - Glob
  - Grep
---

# Manage and Validate Current Priorities

**Action**: $ARGUMENTS (defaults to 'review' if not specified)
**CLI Script**: `scripts/update-priorities.sh` (data gathering)
**Workflow Reference**: @.claude/context/workflows/priority-validation-workflow.md

---

## Parse Arguments

```
If $ARGUMENTS is empty or "review":
  → Run Review Mode

If $ARGUMENTS starts with "add":
  → Run Add Mode with remaining text as priority description

If $ARGUMENTS starts with "complete":
  → Run Complete Mode with remaining text as item to complete

If $ARGUMENTS starts with "plan":
  → Run Plan Mode with remaining text as item to plan
```

---

## Section A: Review Mode

### Step 1: Gather Data (CLI)

Run these commands to collect system state:

```bash
# Quick summary
scripts/update-priorities.sh --summary

# Parse priorities structure
scripts/update-priorities.sh --parse-priorities

# Recent git history
scripts/update-priorities.sh --git-history 30

# System state (Docker, MCP, SSH, cron)
scripts/update-priorities.sh --system-state
```

### Step 2: Analyze Data (AI Judgment)

Based on the gathered data:

1. **Load priorities file**: Read `.claude/context/projects/current-priorities.md`

2. **Cross-reference items**:
   - Match "In Progress" items against git commits
   - Check completed checkbox items `[x]` for evidence
   - Look for items mentioned in git but not in priorities (false negatives)

3. **Classify each item**:
   - ✅ **Verified**: Has git evidence AND/OR system verification
   - ⚠️ **Completed but not archived**: Marked `[x]` but still in active sections
   - ❌ **False positive**: Marked done but no evidence found
   - 🔍 **False negative**: Evidence exists but not marked done
   - 🗑️ **Outdated**: No activity 30+ days, unclear value

4. **Assess evidence quality**:
   - 🟢 **Strong**: Git commit + service verified + documented
   - 🟡 **Weak**: Partial evidence (old commit, unclear status)
   - 🔴 **None**: No evidence found

### Step 3: Generate Report

```
Priority Validation Report - [DATE]

=== SUMMARY ===
✅ Verified accurate: [COUNT]
⚠️  Completed (not archived): [COUNT]
❌ Discrepancies: [COUNT]
🗑️  Outdated: [COUNT]

=== COMPLETED ITEMS (Ready for Archive) ===
[List with evidence and confidence]

=== DISCREPANCIES ===
[False positives/negatives with details]

=== RECOMMENDATIONS ===
[Actionable steps - no changes without user approval]
```

### Step 4: User Confirmation

Ask before making any changes:
- Which completed items to archive?
- Which statuses to update?
- Apply changes and commit?

---

## Section B: Add Mode

### Step 1: Parse New Priority

Extract priority description from `$ARGUMENTS` (everything after "add").

### Step 2: Ask Clarifying Questions (AI Judgment)

1. **Timeframe**: This Week / This Month / Backlog?
2. **Dependencies**: What must be done first?
3. **Acceptance criteria**: How do you know it's done?

### Step 3: Format and Add

```markdown
- [ ] [Priority description]
  - Dependencies: [if any]
  - Acceptance: [criteria]
```

Add to appropriate section in current-priorities.md.

### Step 4: Offer to Commit

```bash
git add .claude/context/projects/current-priorities.md
git commit -m "Add priority: [brief description]

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Section C: Complete Mode

### Step 1: Find Item

Search for the item using CLI:

```bash
scripts/update-priorities.sh --search "[item description]"
```

If not found, report and ask for clarification.

### Step 2: Gather Evidence (CLI)

```bash
scripts/update-priorities.sh --evidence "[item description]"
```

This returns:
- Git commits mentioning the item
- Session notes mentioning the item
- Context files mentioning the item
- Service status (if applicable)

### Step 3: Verify Completion (AI Judgment)

Based on evidence:

1. **Assess evidence quality** (🟢🟡🔴)
2. **Verify system state** if applicable:
   - Service running?
   - Config exists?
   - SSH accessible?
3. **Ask user to confirm** if evidence is weak

### Step 4: Move to Completed Section

```markdown
### [DATE] ([Brief Description])
- [x] [Original priority text]
  - Evidence: [git commit, service status, etc.]
```

### Step 5: Ask for Follow-ups

"Are there any follow-up tasks from completing this?"

### Step 6: Offer to Commit

---

## Section D: Plan Mode

### Step 1: Identify Item

If specific item provided:
```bash
scripts/update-priorities.sh --search "[item]"
```

If no item, load current-priorities.md and ask what to focus on.

### Step 2: Gather Context (CLI)

```bash
# Recent activity
scripts/update-priorities.sh --summary

# Related commits
scripts/update-priorities.sh --git-history 14
```

### Step 3: Break Down Priority (AI Judgment)

For the selected item:

1. **Analyze scope and complexity**
2. **Identify dependencies**
3. **Create phased breakdown**:

```markdown
Phase 1: [Name] ([estimate])
- [ ] Task 1
- [ ] Task 2

Phase 2: [Name] ([estimate])
- [ ] Task 1
- [ ] Task 2

Dependencies: [list]
Estimated total: [X hours/days]
```

### Step 4: Update Priorities File

Add breakdown under the original item or create new section.

### Step 5: Offer to Commit

---

## CLI Script Reference

```bash
# Quick summary stats
scripts/update-priorities.sh --summary

# Parse priorities file structure
scripts/update-priorities.sh --parse-priorities

# Get git history (default 30 days)
scripts/update-priorities.sh --git-history [days]

# Get session notes (default 5)
scripts/update-priorities.sh --session-notes [count]

# Get system state (Docker, MCP, SSH, cron)
scripts/update-priorities.sh --system-state

# Search priorities for term
scripts/update-priorities.sh --search "term"

# Gather evidence for item
scripts/update-priorities.sh --evidence "item"
```

---

## Evidence Quality Standards

### 🟢 Strong Evidence
- Git commit with descriptive message
- Service running/config verified
- Documentation exists
- Session notes confirm completion

### 🟡 Weak Evidence
- Old commit without clear completion
- Service exists but status unclear
- Partial documentation
- User mention without verification

### 🔴 No Evidence
- No git history found
- Service not running/missing
- No documentation
- No session note mentions

---

## Related

- Script: @Scripts/update-priorities.sh
- Priorities: @.claude/context/projects/current-priorities.md
- Workflow: @.claude/context/workflows/priority-validation-workflow.md
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
- Session Exit: @.claude/context/workflows/session-exit-procedure.md

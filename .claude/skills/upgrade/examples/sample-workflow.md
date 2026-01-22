# Sample Upgrade Workflow

This example demonstrates a complete upgrade workflow from discovery to implementation.

---

## Scenario

You want to check if there are any new Claude Code releases or improvements you should apply.

---

## Step 1: Discovery

```bash
/upgrade discover
```

**Output**:
```
Discovery Report - 2026-01-21
=============================
Sources checked: 6
New discoveries: 2

CRITICAL:
- [UP-001] Claude Code 2.2.0 released
  - New hook events: PreToolUse, PostToolUse validation
  - Improved MCP error handling
  - Source: claude-code-releases

HIGH:
- [UP-002] New "use when" field for hooks
  - Anthropic recommends: "use when" over "what it does"
  - Source: engineering-blog

Run /upgrade analyze to evaluate relevance.
```

---

## Step 2: Analysis

```bash
/upgrade analyze
```

**Output**:
```
Analysis Complete
=================

UP-001: Claude Code 2.2.0
  Relevance Score: 9/10
  - Category Match: +3 (affects hooks, MCP)
  - Recency: +2 (released yesterday)
  - Security: +1 (includes security fixes)
  - Breaking Changes: +0 (none)
  Impact: HIGH
  Complexity: LOW (just npm update)

UP-002: "use when" hook field
  Relevance Score: 7/10
  - Category Match: +3 (affects hooks)
  - Recency: +1 (article from last week)
  - Security: +0
  - Breaking Changes: +0
  Impact: MEDIUM
  Complexity: MEDIUM (update 5 hook files)

Recommendation: Start with UP-001 (higher score, lower complexity)
```

---

## Step 3: Proposal

```bash
/upgrade propose UP-001
```

**Output**:
```
Upgrade Proposal: UP-001
========================

Title: Claude Code 2.2.0
Source: claude-code-releases
Score: 9/10 | Impact: HIGH | Complexity: LOW

Summary:
  Major release with new hook events and improved MCP handling.
  Includes security patches.

Files to Modify:
  - None (npm package update)

Commands to Run:
  npm update -g @anthropic-ai/claude-code

Risks:
  - Low: New hook events may require testing
  - Mitigation: Test hooks after update

Rollback:
  - Tag: pre-UP-001
  - Command: npm install -g @anthropic-ai/claude-code@2.1.14

Estimated Effort: 5 minutes

To implement: /upgrade implement UP-001
To defer: /upgrade defer UP-001 "reason"
```

---

## Step 4: Implementation

After reviewing the proposal:

```bash
/upgrade implement UP-001
```

**Output**:
```
Implementing UP-001: Claude Code 2.2.0
======================================

[1/4] Creating checkpoint...
  Tag created: pre-UP-001

[2/4] Applying changes...
  Running: npm update -g @anthropic-ai/claude-code
  Updated: 2.1.14 -> 2.2.0

[3/4] Validating...
  Claude Code version: 2.2.0 OK
  Hook system: OK
  MCP connections: OK

[4/4] Logging...
  History updated: upgrade-history.jsonl
  Baselines updated: baselines.json

Upgrade UP-001 applied successfully.

Next: Test your hooks to ensure compatibility.
If issues: /upgrade rollback UP-001
```

---

## Step 5: Verification

After using Claude Code for a bit:

```bash
/upgrade status
```

**Output**:
```
Upgrade Status
==============

Pending upgrades: 1
  - UP-002: "use when" hook field (Score: 7)

Recent upgrades (last 7 days):
  - UP-001: Claude Code 2.2.0 (applied 2026-01-21)

Components:
  - claude-code: 2.2.0 (updated today)
  - mcp-git: 2024.1
  - mcp-filesystem: 2024.1

Next discovery due: 2026-01-22 (daily sources)
```

---

## Rollback (if needed)

If UP-001 caused issues:

```bash
/upgrade rollback UP-001
```

**Output**:
```
Rolling back UP-001
===================

[1/3] Restoring from checkpoint...
  Using tag: pre-UP-001
  Running: npm install -g @anthropic-ai/claude-code@2.1.14

[2/3] Validating...
  Claude Code version: 2.1.14 OK

[3/3] Updating history...
  Status changed: applied -> rolled_back
  Reason: User initiated rollback

Rollback complete.
UP-001 has been reverted.
```

---

## Tips

1. **Run discovery weekly**: `/upgrade discover` catches updates you might miss
2. **Review before implementing**: Always read the proposal
3. **One at a time**: Don't batch unrelated upgrades
4. **Test after**: Verify your workflows still work
5. **Log learnings**: Note any issues in the history

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `/upgrade discover` | Find new updates |
| `/upgrade analyze` | Score and prioritize |
| `/upgrade propose [id]` | See implementation details |
| `/upgrade implement <id>` | Apply approved upgrade |
| `/upgrade status` | Current state |
| `/upgrade history` | Past upgrades |
| `/upgrade rollback <id>` | Undo an upgrade |

# Plan: Command-to-Skill Migration & Native Command Restoration

## Executive Summary

Migrate custom Jarvis commands to the Skills architecture while restoring native Claude Code commands. This is a clean-break migration affecting 60+ command files and 62 documentation files.

**Key Decisions:**
1. Convert conflicts to skills only (not slash-invocable)
2. Leverage existing `autonomous-commands` skill infrastructure
3. Use tmux capture pattern for output visibility
4. Clean break - no deprecation period

---

## Problem Statement

1. **Native Command Conflicts**: 4+ custom commands override native Claude Code functionality
2. **Architecture Gap**: Commands lack progressive disclosure, arguments, and autonomic output capture
3. **Documentation Debt**: 268 command references across 62 files need updating

---

## Design Principles

### Autonomic Output Capture Pattern

All Skills must ensure Jarvis can review command output. Pattern using tmux:

```bash
# 1. Send command to Claude Code session
tmux send-keys -t claude-session '/context' Enter

# 2. Wait for output
sleep 2

# 3. Capture and return output to Jarvis
tmux capture-pane -t claude-session -p
```

This replaces the signal-watcher approach with direct output capture.

### Skill Design Requirements

Every skill MUST:
1. **Return data to Jarvis** - Use tmux capture or structured output files
2. **Not pause execution** - No interactive prompts, no screen changes
3. **Support flags** - For optional behaviors (e.g., `--verbose`, `--dry-run`)
4. **Log actions** - Write to `.claude/logs/` for audit trail

---

## Migration Inventory

### Phase 1: Remove Conflicting Commands (4 files)

| Current Command | Action | Native Restored |
|-----------------|--------|-----------------|
| `/help` | DELETE | Native `/help` |
| `/status` | DELETE | Native `/status` |
| `/compact` | DELETE | Native `/compact` |
| `/clear` | DELETE | Native `/clear` |

These become skills (not slash-invocable) for when Jarvis needs enhanced versions.

### Phase 2: Convert Session Commands to Skills (8 commands)

| Command | New Skill | Notes |
|---------|-----------|-------|
| `/setup` | `session-setup` | Wizard for initial config |
| `/setup-readiness` | Merge into `session-setup` | Post-setup validation |
| `/end-session` | `session-management` | Already exists, enhance |
| `/checkpoint` | `session-management` | Merge checkpoint logic |
| `/context-budget` | `context-management` | New skill |
| `/context-checkpoint` | `context-management` | Merge |
| `/context-analyze` | `context-management` | Merge |
| `/smart-compact` | `context-management` | Merge JICM logic |

### Phase 3: Convert Self-Improvement Commands (5 commands)

| Command | New Skill | Notes |
|---------|-----------|-------|
| `/reflect` | `self-improvement` | AC-05 trigger |
| `/evolve` | `self-improvement` | AC-06 trigger |
| `/research` | `self-improvement` | AC-07 trigger |
| `/maintain` | `self-improvement` | AC-08 trigger |
| `/self-improve` | `self-improvement` | Meta-trigger for all |

### Phase 4: Convert Validation Commands (5 commands)

| Command | New Skill | Notes |
|---------|-----------|-------|
| `/tooling-health` | `validation` | MCP/hook/skill validation |
| `/health-report` | `validation` | System health |
| `/validate-selection` | `validation` | Tool selection quality |
| `/design-review` | `validation` | PARC pattern review |
| `/validate-mcp` | Merge into `mcp-validation` | Already exists |

### Phase 5: Convert Auto-* Commands (17 commands)

All auto-* commands merge into the **existing** `autonomous-commands` skill (not a new skill):

| Command | Action | Notes |
|---------|--------|-------|
| `/auto-status` | Merge into `autonomous-commands` | Enhances existing skill |
| `/auto-doctor` | Merge into `autonomous-commands` | |
| `/auto-cost` | Merge into `autonomous-commands` | |
| `/auto-usage` | Merge into `autonomous-commands` | |
| `/auto-stats` | Merge into `autonomous-commands` | |
| `/auto-context` | Merge into `autonomous-commands` | |
| `/auto-todos` | Merge into `autonomous-commands` | |
| `/auto-hooks` | Merge into `autonomous-commands` | |
| `/auto-bashes` | Merge into `autonomous-commands` | |
| `/auto-review` | Merge into `autonomous-commands` | |
| `/auto-plan` | Merge into `autonomous-commands` | |
| `/auto-export` | Merge into `autonomous-commands` | |
| `/auto-resume` | Merge into `autonomous-commands` | |
| `/auto-rename` | Merge into `autonomous-commands` | |
| `/auto-release-notes` | Merge into `autonomous-commands` | |
| `/auto-security-review` | Merge into `autonomous-commands` | |
| `/auto-settings` | DELETE | Use native `/status` |

**Leverage existing infrastructure**: The `autonomous-commands` skill + `signal-helper.sh` already implement the correct architecture. Delete the 17 thin wrapper command files.

### Commands That SHOULD Remain as Commands

Some commands benefit from command frontmatter (`allowed-tools`, etc.) and complex workflows:

| Command | Reason to Keep |
|---------|----------------|
| `/end-session` | Complex git workflow, needs `allowed-tools: Bash(git:*)` |
| `/checkpoint` | MCP-related operations, specific tool permissions |
| `/setup` | Initial configuration - must work before skills load |
| `/tooling-health` | Complex multi-phase validation workflow |
| `/reflect` | Generates reports to specific paths |

These remain in `.claude/commands/` but should be renamed if they conflict with native commands.

### Phase 6: Convert Utility Commands (15+ commands)

| Command | New Skill | Notes |
|---------|-----------|-------|
| `/jarvis` | `jarvis-menu` | Quick access menu |
| `/agent` | Keep as command | Simple agent launcher |
| `/capture` | `capture` | Screenshot capture |
| `/history` | `history` | Command history |
| `/analyze-codebase` | `codebase-analysis` | Structure analysis |
| `/ralph-loop` | `ralph-loop` | Already a skill concept |
| `/cancel-ralph` | Merge into `ralph-loop` | |
| `/orchestration:*` | `orchestration` | Consolidate 4 commands |
| `/commits:*` | `commits` | Consolidate 2 commands |
| `/create-project` | `project-management` | |
| `/register-project` | `project-management` | |
| `/sync-aifred-baseline` | `aifred-sync` | Upstream sync |

---

## Documentation Update Plan

### Tier 1: Core Identity (Update First)

1. **`.claude/CLAUDE.md`** - Update command table to skill references
2. **`.claude/context/reference/commands-quick-ref.md`** - Rename to `skills-quick-ref.md`
3. **`.claude/context/psyche/pneuma-map.md`** - Update capability inventory
4. **`.claude/context/integrations/capability-matrix.md`** - Update task-to-skill matrix

### Tier 2: Component Specifications (9 files)

- AC-01 through AC-09 component files
- Update trigger mechanisms from commands to skills

### Tier 3: Guides (4 files)

- `autonomous-commands-guide.md` → `skills-execution-guide.md`
- `autonomous-commands-quickstart.md` → DELETE (merge into guide)
- Update all guide cross-references

### Tier 4: Patterns (24 files)

- Update command references in all pattern files
- Key files:
  - `command-invocation-pattern.md` → `skill-invocation-pattern.md`
  - `command-signal-protocol.md` → `skill-execution-protocol.md`
  - `self-monitoring-commands.md` → `self-monitoring-skills.md`

### Tier 5: Supporting Docs (20+ files)

- Integration docs, standards, workflows
- Search-and-replace pass for remaining references

---

## New Skill Structure

### native-command-runner Skill

```
.claude/skills/native-command-runner/
├── SKILL.md              # Main skill definition
├── scripts/
│   └── run-native.sh     # tmux capture implementation
└── references/
    └── supported-commands.md  # List of capturable commands
```

**SKILL.md Frontmatter:**
```yaml
name: native-command-runner
description: |
  Execute native Claude Code commands and capture output for Jarvis review.
  Use when: Jarvis needs to see output of /doctor, /usage, /stats, /context, etc.
  Supports: doctor, usage, stats, context, todos, hooks, cost, review, plan
user_invocable: true
arguments:
  - name: command
    description: Native command to run (without slash)
    required: true
  - name: args
    description: Optional command arguments
    required: false
```

### context-management Skill

```
.claude/skills/context-management/
├── SKILL.md
├── scripts/
│   ├── analyze-budget.sh
│   ├── checkpoint.sh
│   └── smart-compact.sh
└── references/
    └── jicm-protocol.md
```

### self-improvement Skill

```
.claude/skills/self-improvement/
├── SKILL.md
├── scripts/
│   └── trigger-ac.sh    # Trigger AC-05/06/07/08
└── references/
    └── improvement-cycles.md
```

---

## Implementation Phases

### Phase 1: Foundation (Estimated: 1 session)
- [ ] Create `native-command-runner` skill with tmux capture
- [ ] Delete 4 conflicting commands
- [ ] Test native command restoration

### Phase 2: Session Skills (Estimated: 1 session)
- [ ] Create `context-management` skill
- [ ] Enhance `session-management` skill
- [ ] Delete/migrate 8 session commands

### Phase 3: Improvement Skills (Estimated: 1 session)
- [ ] Create `self-improvement` skill
- [ ] Migrate 5 improvement commands
- [ ] Delete old command files

### Phase 4: Validation & Utility Skills (Estimated: 1 session)
- [ ] Create `validation` skill
- [ ] Consolidate utility commands
- [ ] Delete migrated command files

### Phase 5: Auto-* Migration (Estimated: 1 session)
- [ ] Migrate all 17 auto-* to `native-command-runner`
- [ ] Delete auto-* command files
- [ ] Remove signal-watcher infrastructure (optional)

### Phase 6: Documentation Sweep (Estimated: 2 sessions)
- [ ] Update Tier 1 docs
- [ ] Update Tier 2-3 docs
- [ ] Search-replace pass for remaining references
- [ ] Validate all internal links

---

## Verification

### Functional Tests
1. Native `/help`, `/status`, `/compact`, `/clear` work
2. Skills can be invoked and capture output
3. Jarvis can autonomically use skills

### Documentation Tests
1. No broken internal links
2. No references to deleted commands
3. CLAUDE.md reflects new architecture

### Regression Tests
1. Session start (AC-01) still works
2. Context management (AC-04/JICM) still works
3. Self-improvement cycles (AC-05-08) still trigger

---

## Files to Delete (Command Directory)

After migration, delete from `.claude/commands/`:
- `help.md`
- `status.md`
- `jicm-compact.md`
- `trigger-clear.md`
- All `auto-*.md` files (17)
- Session commands migrated to skills
- Self-improvement commands migrated to skills
- Validation commands migrated to skills
- Utility commands consolidated into skills

**Estimated deletions: ~45 command files**

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| **tmux session naming conflicts** | Use consistent session name; add session detection |
| **Output capture timing** | Configurable sleep delays, output stabilization checks |
| **Missing documentation updates** | Grep sweep for `/command` patterns post-migration |
| **Skill discovery issues** | Test frontmatter triggers; add transition mapping doc |
| **Additional native conflicts** | `/doctor`, `/context`, `/usage`, `/cost`, `/todos`, `/hooks`, `/stats` are also native - verify no conflicts |
| **Watcher dependency** | Skills fail silently if watcher not running - add health check |
| **Context cost of skill loading** | Skills load full SKILL.md (~330 lines); consider lighter invocation |
| **Signal-helper blocklist approach** | Prefer blocklist (permissive) over whitelist for extensibility |
| **User discoverability** | Users accustomed to `/auto-status` may not find skill equivalent - document transition |

### tmux Edge Cases

1. **Session name mismatch**: Hardcoded `TMUX_SESSION="jarvis"` - fails if renamed
2. **Timing races**: 0.3s delays may fail on slow systems - consider exponential backoff
3. **Input buffer state**: Keystroke injection may corrupt input if Claude is mid-response
4. **AppleScript fallback**: Degraded mode requires manual Enter press
5. **No output capture yet**: Watcher can SEND but not CAPTURE output - use statusline for output

---

## Transition Mapping (User Reference)

Create this doc for users migrating from old commands:

| Old Command | New Invocation |
|-------------|----------------|
| `/help` | Native `/help` (restored) |
| `/status` | Native `/status` (restored); Jarvis status via skill |
| `/compact` | Native `/compact` (restored) |
| `/clear` | Native `/clear` (restored) |
| `/auto-status` | Skill: "run native status and show output" |
| `/auto-doctor` | Skill: "run native doctor check" |
| `/auto-*` | Skill: `autonomous-commands` with command name |
| `/jarvis` | Skill: "show jarvis menu" |

---

## Success Criteria

1. Zero custom commands override native Claude Code commands
2. All Jarvis functionality preserved via Skills
3. Jarvis can autonomically execute and review native command output
4. Documentation fully updated with no dead references
5. Clean git history with atomic commits per phase
6. Transition mapping documented for user migration

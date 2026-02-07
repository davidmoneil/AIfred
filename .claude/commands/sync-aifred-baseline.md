---
description: Sync and analyze AIfred baseline changes for controlled porting
allowed-tools: Read, Write, Edit, Bash(git:*), Glob, Grep
---

# Sync AIfred Baseline

You are running the Jarvis upstream sync workflow to analyze AIfred baseline changes.

**CRITICAL CONSTRAINT**: The AIfred baseline at `/Users/aircannon/Claude/AIfred` is **READ-ONLY**.
Only `git fetch` and `git pull` operations are allowed. Never edit, commit, branch, or configure it.

## Arguments

- `$ARGUMENTS` — Optional: "dry-run" (report only) or "full" (include patch generation)
  - Default is "dry-run" if not specified

## MANDATORY OUTPUTS

**Every invocation MUST generate TWO report files:**

1. **Formal Sync Report**: `projects/project-aion/evolution/aifred-integration/sync-reports/sync-report-YYYY-MM-DD.md`
   - Structured ADOPT/ADAPT/REJECT/DEFER classifications
   - File-by-file analysis
   - Rationales for each decision

2. **Ad-Hoc Assessment**: `projects/project-aion/evolution/aifred-integration/sync-reports/adhoc-assessment-YYYY-MM-DD.md`
   - Key discoveries (what was unexpected or important)
   - Questions resolved during analysis
   - Implications for Jarvis architecture
   - Recommended next steps
   - Any blockers or concerns

**These reports are NOT optional** — they must be written to disk before the command completes.

## Phase 1: Fetch Baseline Updates

```bash
cd /Users/aircannon/Claude/AIfred && git fetch origin && git status
```

If updates are available:
```bash
cd /Users/aircannon/Claude/AIfred && git pull origin main
```

Record the current baseline commit:
```bash
cd /Users/aircannon/Claude/AIfred && git rev-parse HEAD
```

## Phase 2: Generate Diff Report

Compare the AIfred baseline `main` branch to Jarvis's divergence point.

### 2.1 Identify Jarvis Baseline Reference

Check `paths-registry.yaml` for `aifred_baseline.last_synced_commit` to find when Jarvis last synced.

### 2.2 Generate File-Level Diff

```bash
# From the AIfred baseline directory
cd /Users/aircannon/Claude/AIfred

# Get list of changed files since last sync point
git diff --name-status <last_synced_commit>..HEAD
```

### 2.3 Categorize Changes

For each changed file, categorize by type:

| Category | Files |
|----------|-------|
| **Hooks** | `.claude/hooks/*.js` |
| **Commands** | `.claude/commands/*.md` |
| **Patterns** | `.claude/context/patterns/*.md` |
| **Agents** | `.claude/agents/*.md` |
| **Core Config** | `CLAUDE.md`, `settings.json` |
| **Documentation** | `docs/**/*.md`, `README.md` |
| **Scripts** | `scripts/**/*` |
| **Other** | Everything else |

## Phase 3: Analyze Each Change

For each significant change, determine:

### Classification Criteria

**ADOPT** (Take directly):
- Bug fixes that apply to Jarvis
- New patterns that don't conflict
- Documentation improvements (generic)
- Hook improvements for shared functionality

**ADAPT** (Modify for Jarvis):
- Changes that reference "AIfred" terminology → rename to "Jarvis/Aion"
- Patterns that work but need Jarvis-specific paths
- Features that need integration with existing Jarvis systems

**REJECT** (Skip):
- Changes that conflict with Jarvis divergence
- Features Jarvis already implements differently
- Breaking changes to systems Jarvis has customized
- Changes superseded by Jarvis improvements

**DEFER** (Review later):
- Complex changes requiring more context
- Changes with unclear implications
- Large refactors needing dedicated time

## Phase 4: Generate Report

Create a structured report at `projects/project-aion/evolution/aifred-integration/sync-reports/sync-report-YYYY-MM-DD.md`:

```markdown
# AIfred Baseline Sync Report

**Generated**: YYYY-MM-DD HH:MM
**Baseline Commit**: <commit_hash>
**Previous Sync**: <last_synced_commit>
**Changes Since**: N files changed

---

## Summary

| Classification | Count |
|----------------|-------|
| ADOPT | N |
| ADAPT | N |
| REJECT | N |
| DEFER | N |

---

## Detailed Analysis

### ADOPT (Ready to Port)

#### [filename]
- **Change**: [description]
- **Rationale**: [why adopt]
- **Action**: Copy/apply directly

### ADAPT (Needs Modification)

#### [filename]
- **Change**: [description]
- **Modification Needed**: [what to change]
- **Rationale**: [why adapt vs adopt]

### REJECT (Skip)

#### [filename]
- **Change**: [description]
- **Rationale**: [why reject]
- **Jarvis Alternative**: [if applicable]

### DEFER (Review Later)

#### [filename]
- **Change**: [description]
- **Reason for Deferral**: [why defer]
- **Review By**: [suggested timeframe]

---

## Recommended Actions

1. [First recommended action]
2. [Second recommended action]
...

---

## Update Port Log?

If proceeding with any ports, update `projects/project-aion/evolution/aifred-integration/port-log.md`.
```

## Phase 5: Update Tracking (If Not Dry-Run)

If `$ARGUMENTS` is "full" and user approves:

1. Update `paths-registry.yaml` → `aifred_baseline.last_synced_commit`
2. Append to `projects/project-aion/evolution/aifred-integration/port-log.md`
3. Create patches for ADOPT items (optional)

## Phase 6: Generate Ad-Hoc Assessment

Create an ad-hoc assessment at `projects/project-aion/evolution/aifred-integration/sync-reports/adhoc-assessment-YYYY-MM-DD.md`:

```markdown
# AIfred Sync Ad-Hoc Assessment

**Generated**: YYYY-MM-DD HH:MM
**Baseline Commit**: <commit_hash>

---

## Key Discoveries

- [Unexpected findings during analysis]
- [Important patterns or implications]
- [Jarvis capabilities that exceeded AIfred]

---

## Questions Resolved

| Question | Resolution |
|----------|------------|
| [Question from analysis] | [Answer/finding] |

---

## Implications for Jarvis

- [How this affects Jarvis architecture]
- [New capabilities enabled]
- [Potential conflicts or concerns]

---

## Recommended Next Steps

1. [Immediate action]
2. [Follow-up action]
3. [Future consideration]

---

## Blockers or Concerns

- [Any issues that need resolution]
- [Dependencies or prerequisites]

---

*Assessment generated during /sync-aifred-baseline*
```

## Output

After completing the sync, provide:

```
AIfred Baseline Sync Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Baseline Status: [up-to-date / N commits behind]
📝 Baseline Commit: <short_hash>
📅 Last Jarvis Sync: <date>

Changes Analyzed:
├── ADOPT:  N items ready to port
├── ADAPT:  N items need modification
├── REJECT: N items skipped
└── DEFER:  N items for later review

Reports Generated:
├── Formal: projects/project-aion/evolution/aifred-integration/sync-reports/sync-report-YYYY-MM-DD.md
└── Ad-Hoc: projects/project-aion/evolution/aifred-integration/sync-reports/adhoc-assessment-YYYY-MM-DD.md

Next Steps:
- [Recommended actions based on findings]
```

---

## Quick Reference

| Mode | What It Does |
|------|--------------|
| `/sync-aifred-baseline` | Dry-run: analyze and report only |
| `/sync-aifred-baseline full` | Full: analyze, report, and offer to apply |

---

*Jarvis v1.2.0 — Project Aion Master Archon*

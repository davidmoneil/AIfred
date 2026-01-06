# PR-4 Implementation Plan: Setup Preflight + Guardrails

**Target Version**: 1.3.0
**Branch**: Project_Aion
**Estimated Effort**: 12-16 hours
**Structure**: Split into 3 sub-PRs

---

## Overview

PR-4 transforms `/setup` into a "preflight + configure + verify" wizard with:
1. **Preflight checks** — Environment validation before setup begins
2. **Permission allowlists** — Workspace boundary definitions
3. **Guardrails** — Hooks that block dangerous operations
4. **Readiness report** — Deterministic pass/fail output
5. **Interactive permissions** — Formalized ad-hoc permission pattern for policy-crossing operations

---

## Sub-PR Structure

### PR-4a: Guardrail Hooks (v1.2.1)
- workspace-guard.js hook
- dangerous-op-guard.js hook
- permission-gate.js hook (formalized ad-hoc pattern)
- Settings.json deny pattern updates

### PR-4b: Preflight System (v1.2.2)
- workspace-allowlist.yaml config
- 00-preflight.md phase
- Updated 00-prerequisites.md

### PR-4c: Readiness Report (v1.3.0)
- setup-readiness.md command
- Updated setup.md and finalization
- Documentation updates
- Final version bump

---

## Design Decisions (User Confirmed)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Ad-hoc permission pattern | **Formalize in PR-4** | Create permission-gate.js hook that uses system prompts to request confirmation for policy-crossing operations |
| Hook error behavior | **Fail-open with warning** | Prioritize availability; log prominent `[!] HIGH` warning when hook can't verify safety |
| PR scope | **Split into 3 sub-PRs** | PR-4a (hooks), PR-4b (preflight), PR-4c (readiness) |

---

## Implementation Phases

### Phase 1: Foundation (Files Only)

| Task | File | Action |
|------|------|--------|
| Create allowlist config | `.claude/config/workspace-allowlist.yaml` | NEW |
| Create preflight phase | `.claude/archive/setup-phases/00-preflight.md` | NEW |
| Update prerequisites | `.claude/archive/setup-phases/00-prerequisites.md` | MODIFY |

**workspace-allowlist.yaml** structure:
```yaml
version: "1.0"
core_workspaces:
  jarvis:
    path: "/Users/aircannon/Claude/Jarvis"
    permissions: [read, write, execute]
readonly_workspaces:
  aifred_baseline:
    path: "/Users/aircannon/Claude/AIfred"
    permissions: [read]
    blocked: [write, edit, delete, commit]
project_workspaces: []  # Populated by /register-project
forbidden_paths: ["/", "/etc", "/usr", "/bin", "~/.ssh", "~/.gnupg"]
```

### Phase 2: Guardrail Hooks (PR-4a)

| Task | File | Action |
|------|------|--------|
| Create workspace guard | `.claude/hooks/workspace-guard.js` | NEW |
| Create dangerous op guard | `.claude/hooks/dangerous-op-guard.js` | NEW |
| Create permission gate | `.claude/hooks/permission-gate.js` | NEW |
| Update hooks README | `.claude/hooks/README.md` | MODIFY |

**workspace-guard.js** — PreToolUse hook that:
- Blocks Write/Edit to AIfred baseline (always)
- Blocks operations to forbidden paths
- Warns on operations outside allowlisted workspaces
- **Fail-open**: On config load error, logs `[!] HIGH` warning but allows operation

**dangerous-op-guard.js** — PreToolUse hook that:
- Blocks destructive patterns (`rm -rf /`, `mkfs`, etc.)
- Blocks force push to main/master
- Warns on `rm -r`, `git reset --hard`
- **Fail-open**: On pattern match error, logs warning but allows operation

**permission-gate.js** — UserPromptSubmit hook that:
- Detects policy-crossing operations (e.g., "push to AIfred", "delete protected")
- Injects system prompt requesting explicit confirmation
- Formalizes the ad-hoc permission pattern tested in PR-3 validation
- Used for soft gates (operations that aren't blocked but need acknowledgment)

### Phase 3: Settings Integration

| Task | File | Action |
|------|------|--------|
| Add baseline deny patterns | `.claude/settings.json` | MODIFY |
| Add forbidden path denies | `.claude/settings.json` | MODIFY |

New deny patterns to add:
```json
"Write(/Users/aircannon/Claude/AIfred/**)",
"Edit(/Users/aircannon/Claude/AIfred/**)",
"Bash(*:/Users/aircannon/Claude/AIfred/*)"
```

### Phase 4: Readiness Report

| Task | File | Action |
|------|------|--------|
| Create readiness command | `.claude/commands/setup-readiness.md` | NEW |
| Update setup to call readiness | `.claude/commands/setup.md` | MODIFY |
| Update finalization phase | `.claude/archive/setup-phases/07-finalization.md` | MODIFY |

**Readiness report** outputs:
- Environment checks (workspace, baseline isolation, git status)
- Prerequisites (Git, Docker, Node versions)
- Permission configuration status
- Guardrail hook validation
- Overall READY/NOT_READY status

### Phase 5: Documentation & Release

| Task | File | Action |
|------|------|--------|
| Add guardrails section | `.claude/CLAUDE.md` | MODIFY |
| Create validation pattern | `.claude/context/patterns/setup-validation.md` | NEW |
| Update priorities | `.claude/context/projects/current-priorities.md` | MODIFY |
| Version bump | `VERSION`, `CHANGELOG.md` | MODIFY |

---

## Key Design Decisions

### 1. Hook-Based Enforcement (Primary)

Hooks provide:
- Detailed logging and user-friendly messages
- External config file loading (allowlist.yaml)
- Runtime flexibility

Settings.json provides defense in depth.

### 2. Multi-Layer Baseline Protection

```
Layer 1: workspace-guard.js hook (blocks Write/Edit)
Layer 2: dangerous-op-guard.js hook (blocks Bash modifications)
Layer 3: settings.json deny patterns
Layer 4: Preflight check validates separation
```

### 3. Preflight Extends Phase 0 (Not New Phase -1)

Preflight becomes "Stage A" of existing Phase 0:
- Stage A: Environment Preflight (new)
- Stage B: Prerequisites Check (existing)

---

## Preflight Checks

| Check | Type | Pass Criteria |
|-------|------|---------------|
| Jarvis workspace exists | REQUIRED | Path exists |
| Jarvis is git repo | REQUIRED | `.git` present |
| AIfred baseline separate | REQUIRED | Paths different |
| Safe working directory | REQUIRED | Not in forbidden paths |
| settings.json exists | RECOMMENDED | File present |
| hooks directory exists | RECOMMENDED | Directory present |
| Git available | REQUIRED | `git --version` works |
| Docker available | OPTIONAL | Docker running |

---

## Files to Create

### PR-4a (Hooks)
1. `.claude/hooks/workspace-guard.js` — Workspace boundary enforcement hook
2. `.claude/hooks/dangerous-op-guard.js` — Dangerous operation blocking hook
3. `.claude/hooks/permission-gate.js` — Formalized ad-hoc permission pattern hook

### PR-4b (Preflight)
4. `.claude/config/workspace-allowlist.yaml` — Workspace boundary definitions
5. `.claude/archive/setup-phases/00-preflight.md` — Preflight stage documentation

### PR-4c (Readiness)
6. `.claude/commands/setup-readiness.md` — Readiness report command
7. `.claude/context/patterns/setup-validation.md` — Validation pattern documentation

---

## Files to Modify

1. `.claude/archive/setup-phases/00-prerequisites.md` — Add preflight stage reference
2. `.claude/archive/setup-phases/07-finalization.md` — Add readiness report call
3. `.claude/commands/setup.md` — Update phase descriptions
4. `.claude/settings.json` — Add baseline deny patterns
5. `.claude/hooks/README.md` — Document new hooks
6. `.claude/CLAUDE.md` — Add guardrails section
7. `.claude/context/projects/current-priorities.md` — Update PR-4 status
8. `VERSION` — Bump to 1.3.0
9. `CHANGELOG.md` — Add PR-4 entries

---

## Implementation Order

### PR-4a: Guardrail Hooks (v1.2.1)
```
1. workspace-guard.js (PreToolUse blocking hook)
2. dangerous-op-guard.js (PreToolUse blocking hook)
3. permission-gate.js (UserPromptSubmit soft-gate hook)
4. settings.json deny pattern updates
5. hooks/README.md documentation
6. Version bump 1.2.0 → 1.2.1
```

### PR-4b: Preflight System (v1.2.2)
```
1. .claude/config/ directory creation
2. workspace-allowlist.yaml configuration
3. 00-preflight.md phase documentation
4. 00-prerequisites.md update (reference preflight)
5. Version bump 1.2.1 → 1.2.2
```

### PR-4c: Readiness Report (v1.3.0)
```
1. setup-readiness.md command
2. setup.md update (phase descriptions)
3. 07-finalization.md update (call readiness)
4. setup-validation.md pattern
5. CLAUDE.md guardrails section
6. current-priorities.md update
7. CHANGELOG.md entries for all PR-4 work
8. Version bump 1.2.2 → 1.3.0
```

---

## Validation Criteria (from Roadmap)

- [ ] Setup produces deterministic pass/fail report
- [ ] "Minimum viable ready" state is testable
- [ ] Setup can run in fresh environment
- [ ] Allowlist boundaries properly enforced
- [ ] Audit logs continue capturing all actions
- [ ] Safety not reduced from current state

---

## Risk Mitigations

| Risk | Mitigation |
|------|------------|
| Hook errors block legitimate ops | Try/catch, fail-open with logging |
| Allowlist too restrictive | Start permissive, tighten based on usage |
| False positives in dangerous op detection | Tune patterns, document overrides |

---

*Plan created: 2026-01-05 — PR-4: Setup Preflight + Guardrails*

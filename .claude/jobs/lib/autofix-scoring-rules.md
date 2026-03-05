# Autofix Scoring Rules

Deterministic scoring criteria for classifying Beads tasks for autonomous execution.
Referenced by: `task-investigator`, `task-score`, `task-executor`, `autofix-executor`.

---

## Label Taxonomy

### `auto:` — Automation Readiness

| Label | Meaning |
|-------|---------|
| `auto:ready` | Execute autonomously after approval — specific paths and actions in description |
| `auto:candidate` | Likely automatable but needs investigation before promotion |
| `auto:blocked` | Needs human input, creative judgment, or external dependency |

### `risk:` — Reversibility

| Label | Meaning |
|-------|---------|
| `risk:safe` | Fully reversible — renames, reports, metadata-only, junk file deletion |
| `risk:moderate` | Reversible with effort — multi-file edits, config changes, directory restructuring |
| `risk:destructive` | Irreversible or externally visible — content deletion, git push, API calls |

---

## Execution Matrix

|  | risk:safe | risk:moderate | risk:destructive |
|---|-----------|---------------|------------------|
| **auto:ready** | Batch approve | Individual approve | Manual only |
| **auto:candidate** | Suggest in digest | Manual only | Manual only |
| **auto:blocked** | Manual | Manual | Manual |

---

## Promotion Criteria (candidate -> ready)

A task should be promoted to `auto:ready` when **ALL** of these are true:

1. **Specific paths** — Task description names exact file/directory paths (not "the config" or "somewhere in the project")
2. **Paths exist** — All referenced paths verified with `ls`/`stat`/`test -e`
3. **Deterministic action** — The fix is unambiguous: rename X to Y, delete file Z, edit line N of file F
4. **No human judgment needed** — No design decisions, no "choose the best approach", no creative work
5. **No external dependencies** — Does not require Docker, SSH, git push, web APIs, or running services
6. **No destructive scope** — Does not delete user content, media files, databases, or Docker volumes
7. **Scoped to known directories** — Operates within project-registered paths

---

## Blocking Criteria (-> auto:blocked)

Block a task if **ANY** of these are true:

1. Has `waiting:external` label — waiting on an external event
2. Has `agent:human` label — explicitly requires human action
3. Vague description — "fix the issue", "clean up", "improve" without specifics
4. Requires design or creative judgment
5. References paths that don't exist
6. Requires Docker operations, SSH, git push, or network calls
7. Involves media file deletion (mp3, m4b, m4a, flac, ogg, opus, wma, aac)
8. Task is already `in_progress` (someone is working on it)

---

## Risk Assignment Rules

| Risk Level | Criteria | Examples |
|-----------|----------|----------|
| `risk:safe` | Single file rename, junk file deletion, metadata-only change, report generation | Rename config files, delete `.DS_Store`, update frontmatter |
| `risk:moderate` | Multi-file edits, config changes, directory restructuring | Edit multiple YAML files, reorganize folder structure |
| `risk:destructive` | Content deletion, any path outside known directories, irreversible operations | Delete media files, git push, API calls, Docker operations |

---

## Auto-Label Assignment by Job

| Job | Default Labels | Reasoning |
|-----|---------------|-----------|
| `rename-file` | `auto:ready,risk:safe` | Single-file rename, fully reversible |
| `update-config` | `auto:candidate,risk:moderate` | Config edits may need review |
| `delete-temp-file` | `auto:ready,risk:safe` | Junk/temp file cleanup |
| `upgrade-discover` | `auto:blocked,risk:moderate` | Always needs human review |
| `docker-cleanup` | `auto:candidate,risk:destructive` | Destructive by nature |

### Example Action Mapping

| Action Type | auto: | risk: |
|------------|-------|-------|
| `rename` | `auto:ready` | `risk:safe` |
| `delete-junk` | `auto:ready` | `risk:safe` |
| `tag-update` | `auto:ready` | `risk:safe` |
| `reorganize` | `auto:candidate` | `risk:moderate` |
| `delete-content` | `auto:blocked` | `risk:destructive` |
| `investigate` | `auto:blocked` | `risk:safe` |

---

## Safety Hard Rules (Executor)

1. **Max 10 tasks per run** — skip remainder
2. **Git stash checkpoint** before any changes (no --include-untracked)
3. **Never delete**: media files (mp3/m4b/m4a/flac/ogg/opus/wma/aac), Docker volumes, databases
4. **Never execute**: Docker operations, SSH, git push, API calls
5. **Never modify**: own persona files, scoring rules, registry.yaml
6. **3-minute timeout** per individual task
7. **When in doubt, skip** — false negatives are safe, false positives are dangerous

---

**Version**: 1.0

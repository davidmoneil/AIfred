# Session Insights Log

**Purpose**: Persistent record of educational insights generated during sessions. These are the `★ Insight` blocks that would otherwise disappear after context clear or session end.

**Format**: Chronological entries grouped by date, categorized by topic.

**Integration**: Jarvis should append new insights here when generating `★ Insight` blocks during sessions.

---

## 2026-02-06

### INS-001: .gitignore Only Affects Untracked Files
**Category**: Git
**Context**: 15 runtime files were committed before .gitignore rules were added

`.gitignore` only prevents **untracked** files from being added. Files already in the git index are tracked forever until explicitly removed with `git rm --cached`. This is a common gotcha — adding a pattern to `.gitignore` after a file is committed does nothing. The fix is `git rm --cached <file>` which removes from the index without touching the working copy on disk.

---

### INS-002: Directory-Scoped vs Global Gitignore Patterns
**Category**: Git
**Context**: Deciding whether to add global `*.png` or directory-specific patterns

A global `*.png` rule prevents committing legitimate small images (icons, diagrams) anywhere in the repo. Scoping the ignore to specific directories (`docs/reports/*.png`, `projects/mtg-card-sales/*.png`) preserves flexibility while solving the immediate problem. Prefer directory-scoped patterns unless you're certain a file type is never wanted anywhere.

---

### INS-003: JICM Compressed Checkpoint Staleness
**Category**: Context Management
**Context**: Checkpoint was 2 commits behind HEAD after restoration

The JICM compression agent captures state at trigger time, but work continues in the main session asynchronously. After context restoration, always verify git log to find the *actual* HEAD state — don't assume the checkpoint matches reality. This is inherent to the async compression architecture and isn't a bug.

---

### INS-004: yq Document Separator Gotcha
**Category**: YAML / Tooling
**Context**: PAT extraction from credentials.yaml included trailing `---\nnull`

When a YAML file ends with a `---` document separator, `yq` treats each separator as a new document. Querying `.key` against the second (empty) document outputs `null`. The fix: always pipe through `head -1 | tr -d '[:space:]'` to isolate the value from the first document.

```bash
# BAD: May include ---\nnull from document separator
yq '.github.pat' credentials.yaml

# GOOD: Isolates first document value, trims whitespace
yq -r '.github.pat' credentials.yaml | head -1 | tr -d '[:space:]'
```

---

### INS-005: PAT Authentication in Git Remotes
**Category**: Git / Authentication
**Context**: Push failed due to expired PAT embedded in remote URL

When you set a remote URL with an embedded PAT (`https://user:TOKEN@github.com/...`), it works until the PAT expires or is rotated. GitHub's password authentication was deprecated in 2021, so HTTPS remotes require PATs. The alternative is SSH keys (`git@github.com:...`), which don't expire the same way but require SSH agent setup. For automation like the watcher, PAT-in-URL is simpler since it doesn't need an SSH agent running.

---

### INS-006: Focused Infrastructure Sprints With Clear Endpoints
**Category**: Project Management
**Context**: JICM 14-day sprint (Jan 23 - Feb 6), v3 to v5.7.0

The JICM sprint is a good example of a focused infrastructure push: clear scope (context management), measurable progress (version numbers), defined endpoint ("production-ready, parked for maintenance"). The danger with infrastructure work is scope creep — the reorientation assessment explicitly recommended parking JICM and returning to the product roadmap (PR-13). Knowing when to stop improving infrastructure and return to feature work is a key judgment call.

---

### INS-007: Self-Correction Sync Gap
**Category**: Self-Improvement / AC-05
**Context**: MEMORY.md had 5 learnings not reflected in self-corrections.md

The auto-capture hook (`self-correction-capture.js`) only catches *user* corrections. Self-discovered bugs documented in MEMORY.md don't automatically flow to the lessons directory. Periodic sync during `/self-improve` cycles closes this gap. Consider: any insight worth recording in MEMORY.md is also worth recording in self-corrections.md.

---

## Template

```markdown
### INS-NNN: Title
**Category**: Category
**Context**: One-line context of when this insight arose

Body: 2-4 sentences explaining the insight, why it matters, and how to apply it.
```

---

*Insights log — Updated by Jarvis during sessions, reviewed during AC-05 reflection.*

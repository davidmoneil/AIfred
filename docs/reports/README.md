# Reports Directory

**Purpose**: Archival reports for auditing and reference (not always-loaded context)

---

## Directory Structure

```
docs/reports/
├── operational/     # Health and tooling reports
├── validation/      # Test procedures and validation runs
└── README.md        # This file
```

---

## Subdirectories

### operational/
Periodic health and status reports:
- `tooling-health-*.md` — Claude Code tooling validation reports

### validation/
Test procedures and validation findings:
- `mcp-validation-*.md` — MCP test results
- `selection-validation-*.md` — Tool selection accuracy tests
- `*-test-procedure.md` — Reusable test procedures

---

## Project Aion Reports

PR-specific reports (design plans, audits, evaluations) are in:
`projects/project-aion/reports/`

---

## When to Consult

Load these reports when:
- Auditing past work
- Reviewing test results
- Debugging recurring issues
- Self-reflection analysis

---

## Related Locations

| Location | Purpose |
|----------|---------|
| `.claude/logs/` | Active operational logs (written by hooks) |
| `docs/archive/` | Cold storage for deprecated items |
| `projects/project-aion/reports/` | PR-specific development reports |

---

*Moved from .claude/reports/ in PR-10 organization cleanup*

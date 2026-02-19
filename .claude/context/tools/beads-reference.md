# Beads Task Management Reference

**Beads (`bd`)** is the primary task management system. All tasks tracked in `.beads/` using the `bd` CLI. The human dashboard is `bv` (beads_viewer TUI) — zero tokens to view.

## Prerequisites

```bash
npm install -g @beads/bd
cd /path/to/project && bd init
cp .beads/config.yaml.template .beads/config.yaml
```

## Core Commands

```bash
# Create (ALWAYS use labels)
bd create "Task title" -t task -p 2 \
  -l "domain:hooks,severity:medium,source:session"

# Update status
bd update <id> --status in_progress --claim    # Start working
bd close <id> --reason "Completed: description"  # Close with reason

# Query (zero-token filtering)
bd list --status open                            # All open tasks
bd list --status open --label domain:hooks       # By domain
bd list --status in_progress                     # Active work
bd ready                                         # Next actionable
```

## Label Convention (REQUIRED on every task)

| Category | Labels | Purpose |
|----------|--------|---------|
| **Domain** | `domain:hooks`, `domain:skills`, `domain:profiles`, `domain:documentation`, `domain:infrastructure` | Work category |
| **Severity** | `severity:critical`, `severity:high`, `severity:medium`, `severity:low` | Impact level |
| **Source** | `source:orchestration`, `source:session`, `source:ad-hoc`, `source:headless` | How created |
| **Agent** | `agent:claude`, `agent:human` | Who created it |

## Shell Aliases

`scripts/beads-aliases.sh` provides zero-token aliases:
- `bd-all` / `bd-next` / `bd-active` / `bd-done` — Status views
- `bd-hooks` / `bd-skills` / `bd-profiles` — Domain views
- `bd-high` / `bd-urgent` — Priority views
- `bd-add "title" domain priority` — Quick create
- `bd-dash` — Open `bv` TUI dashboard

## Session Discipline

- **Claim before starting**: `bd update <id> --status in_progress --claim`
- **Close when done**: `bd close <id> --reason "Completed: ..."`
- If a Beads task exists for ad-hoc work, claim it before starting

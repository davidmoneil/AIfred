# Commands

**Purpose**: Slash command definitions — the actions Jarvis can perform.

**Layer**: Pneuma (capabilities)

---

## Structure

| Directory | Contents |
|-----------|----------|
| `*.md` | Command definition files |
| `commits/` | Commit-related commands |
| `orchestration/` | Orchestration commands |

## Command Categories

### Session Management
- `setup.md`, `end-session.md`, `checkpoint.md`

### Self-Improvement
- `reflect.md`, `evolve.md`, `research.md`, `maintain.md`

### Validation
- `tooling-health.md`, `design-review.md`, `validate-selection.md`

### Autonomous Execution
- Handled by `autonomous-commands` skill (signal-based automation)

### Orchestration
- `orchestration/plan.md`, `orchestration/status.md`, `orchestration/resume.md`

## Creating New Commands

1. Create `<command-name>.md`
2. Include YAML frontmatter with triggers
3. Define command behavior
4. Test invocation

---

*Jarvis — Pneuma Layer (Capabilities)*

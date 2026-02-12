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

### Context & Testing
- `dev-test.md`, `context-analyze.md`, `smart-compact.md`, `context-budget.md`

### Dev Session
- `export-dev.md` — Export W5:Jarvis-dev chat to timestamped file
- `dev-chat.md` — Browse and read saved dev chat exports

### Ulfhedthnar
- `unleash.md`, `disengage.md`

### Milestone & Review
- `review-milestone.md`, `health-report.md`, `housekeep.md`

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

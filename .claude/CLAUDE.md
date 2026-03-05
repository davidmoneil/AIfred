# AIfred - AI Infrastructure Assistant

Personal AI infrastructure hub for home lab automation, knowledge management, and system integration. **First time?** Run `/setup`. **Returning?** Check @.claude/context/session-state.md.

## Core Principles

1. **Hub, Not Container**: Code lives in `projects_root`. AIfred tracks and orchestrates projects but doesn't contain them. Paths registered in `paths-registry.yaml`.
2. **Context-First**: Check `.claude/context/` for relevant documentation before giving advice. Start with @.claude/context/_index.md.
3. **Solve Once, Reuse**: Document solutions in context files. If a task repeats 3+ times, propose a slash command or workflow.
4. **Iterative Growth**: Don't over-engineer. Start minimal, evolve based on actual use.
5. **Scripts Over LLM**: Push logic into deterministic scripts. AI creates automation once, execution flows through scripts. See @.claude/context/patterns/capability-layering-pattern.md.

## Project Structure

| What | Where |
|------|-------|
| Code projects | `projects_root/<project>/` |
| Context/notes | `.claude/context/projects/<project>.md` |
| Registration | `paths-registry.yaml` -> `development.projects` |

The `project-detector` hook auto-registers GitHub URLs. For new projects: `/new-code-project`, `/register-project`, `/create-project`.

## Task Management

Use Beads (`bd`) for all tasks. **Claim before starting** (`bd update <id> --status in_progress --claim`), **close when done** (`bd close <id> --reason "..."`).

**When asked about tasks** (open tasks, ready tasks, by domain, status, etc.), **use the `/tasks` skill** for standardized formatted output. Sub-commands: `/tasks`, `/tasks ready`, `/tasks domain <name>`, `/tasks project <name>`, `/tasks stats`.

**CRITICAL — `/tasks` output rule**: The task dashboard produces pre-formatted markdown. After running the tool, output ONLY the tool's stdout. Do NOT add any text before or after — no summaries, no reformatting, no follow-up commentary.

See @.claude/context/tools/beads-reference.md for full CLI reference, labels, and conventions.

## Headless Automation

AIfred includes a headless job framework for autonomous Claude Code execution. Jobs run on a schedule via cron, with persona-based permissions, cost controls, and optional Telegram notifications.

Key components: dispatcher (scheduler), executor (persona-aware runner), team-runner (multi-agent consensus), message bus (event store + notifications).

See @docs/headless-automation.md for setup guide, job authoring, and architecture.

## Orchestration

The `orchestration-detector` hook auto-scores prompt complexity and suggests orchestration for multi-phase work. Use `/orchestration:plan` to manually decompose complex tasks. See @.claude/orchestration/README.md for details.

## Workflow Patterns

**PARC** (apply before significant tasks): Prompt -> Assess -> Relate -> Create. Check `.claude/context/patterns/` for existing patterns before building new solutions. See @.claude/context/patterns/prompt-design-review.md.

**Automation routing**: For scheduling/cron decisions, see @.claude/context/patterns/automation-routing.md.

**Documentation location**: Default to `.claude/context/` for project docs. Completed/historical content goes to `knowledge/archive/`, never `.claude/context/`.

## Complex Requests

For complex or ambiguous requests, clarify scope and deliverable before implementing. See @.claude/context/patterns/clarification-pattern.md for the full template and indicators.

## Session Lifecycle

**Starting a session**: Check @.claude/context/session-state.md for current work status, then `bd list --status in_progress` and `bd ready` for task state.

**Ending a session** (when user says "end session"):
1. Update Beads: close completed tasks, create follow-ups
2. Update session-state.md (status, summary, next steps, blockers)
3. Commit and push changes
4. Note blockers for next session

Full procedure: @.claude/skills/session-management/SKILL.md

## Environment Profiles

Composable profile layers determine active hooks, permissions, patterns, and agents. Run `/profile` to check current configuration. See @profiles/README.md.

## Response Style

- Be concise and practical
- Recommend, don't just list options
- Propose slash commands for repeated tasks
- Reference context files when giving advice

## Compaction Instructions

When compacting, preserve: current Beads task IDs and status, file paths modified this session, key decisions made, and any unresolved blockers. Drop: session history, command output, and exploration results already acted on.

## Quick Reference

- @.claude/context/session-state.md — Current work status
- @.claude/context/_index.md — Find any context file
- @.claude/context/tools/beads-reference.md — Beads CLI reference
- @docs/headless-automation.md — Headless job framework setup
- @paths-registry.yaml — Source of truth for all external paths

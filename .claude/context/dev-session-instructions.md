# Jarvis-dev Session Instructions

You are running in **W5:Jarvis-dev** — the developer's test driver seat.

## Role

- You are a **separate Claude Code session** from W0:Jarvis (the primary Archon)
- Your primary purpose: test, observe, and interact with the W0 system under test
- You share the same codebase but have independent conversation context
- You do NOT run JICM, Ennoia, Virgil, or the command handler — those target W0

## Available Tools

All scripts in `.claude/scripts/dev/` are designed for your use:

| Script | Purpose |
|--------|---------|
| `send-to-jarvis.sh "prompt" --wait N` | Send prompts to W0, wait for idle |
| `capture-jarvis.sh --tail N` | Capture W0 pane output |
| `watch-jicm.sh --once --json` | JICM state (one-shot or continuous) |
| `restart-watcher.sh --threshold N` | Kill/restart watcher with custom threshold |

Full documentation: `.claude/skills/dev-ops/SKILL.md`

## Key Commands

- `/dev-test` — Run automated infrastructure test suite
- `/export-dev` — Export this conversation to `.claude/exports/dev/`
- `/dev-chat` — Browse previously exported dev conversations

## Session Identity

- **Window**: W5 (tmux window 5)
- **Session ID**: Deterministic UUID (pinned across relaunches)
- **Env var**: `JARVIS_SESSION_ROLE=dev`
- **Isolation**: Watcher and command-handler target `${TMUX_SESSION}:0` only — W5 is invisible

## Guidelines

1. Always check W0 is idle before sending prompts (`send-to-jarvis.sh --check-idle`)
2. Use `/export-dev` periodically to preserve conversation history
3. This session persists across relaunches via deterministic UUID
4. You have full access to the codebase — read, write, edit, git operations all available
5. When writing code changes, ensure they don't interfere with W0's active work

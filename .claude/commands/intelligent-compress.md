---
description: Intelligent context compression using Claude model to analyze and compress conversation context
allowed-tools: Read, Write, Task, Bash, TaskList
---

# Intelligent Compress (JICM v6.1)

**CRITICAL: Execute silently. No explanations. Tool calls only. Minimize context overhead.**

1. Check flag: `ls .claude/context/.compression-in-progress 2>/dev/null` — if exists, say "Compression already in progress." and STOP.
2. Create flag: `echo "$(date +%s)" > .claude/context/.compression-in-progress`
3. Dump active tasks to file for compression agent: call `TaskList`, then write results to `.claude/context/.active-tasks.txt`. If no tasks exist, write "No active tasks."
4. Parse optional flags from the command invocation:
   - `--model <haiku|sonnet|opus>` — Override model (default: sonnet)
   - `--preassemble` — Run preprocessing script before spawning agent

5. If `--preassemble` was specified:
   a. Run preprocessing: `bash .claude/scripts/dev/preassemble-compression-input.sh`
   b. Spawn agent with Task tool — EXACT parameters:
   ```
   subagent_type: compression-agent-preassembled
   model: [parsed model, default sonnet]
   run_in_background: true
   max_turns: 10
   prompt: Compress current conversation context for JICM v6.1 continuation. Target 5K-15K tokens. Read the pre-assembled input from .claude/context/.compression-input-preassembled.md. Write checkpoint to .claude/context/.compressed-context-ready.md and signal to .claude/context/.compression-done.signal. See compression-agent-preassembled.md for full protocol.
   ```

6. If `--preassemble` was NOT specified (default):
   Spawn agent with Task tool — EXACT parameters:
   ```
   subagent_type: compression-agent
   model: [parsed model, default sonnet]
   run_in_background: true
   max_turns: 30
   prompt: Compress current conversation context for JICM v5.8 continuation. Target 5K-15K tokens. Write checkpoint to .claude/context/.compressed-context-ready.md and signal to .claude/context/.compression-done.signal. See compression-agent.md for full protocol.
   ```

7. Say only: "Compression spawned. Watcher handles /clear and restoration."

Do NOT: update session files, read additional files, verify agent output, or add explanations.
Post-compression gating (.in-progress-ready.md, /clear) is handled entirely by the watcher.

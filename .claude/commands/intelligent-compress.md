---
description: Intelligent context compression using Claude model to analyze and compress conversation context
allowed-tools: Read, Write, Task, Bash
---

# Intelligent Compress (JICM v5.7)

**CRITICAL: Execute silently. No explanations. Tool calls only. Minimize context overhead.**

1. Check flag: `ls .claude/context/.compression-in-progress 2>/dev/null` — if exists, say "Compression already in progress." and STOP.
2. Create flag: `echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.compression-in-progress`
3. Spawn agent with Task tool — EXACT parameters:

```
subagent_type: compression-agent
model: sonnet
run_in_background: true
prompt: Compress current conversation context for JICM v5 continuation. Target 5K-15K tokens. Write to .claude/context/.compressed-context-ready.md and signal to .claude/context/.compression-done.signal. See compression-agent.md for full protocol.
```

4. Say only: "Compression spawned. Watcher handles /clear and restoration."

Do NOT: update session files, read additional files, verify agent output, or add explanations.
The watcher monitors `.compression-done.signal` and handles everything after spawn.

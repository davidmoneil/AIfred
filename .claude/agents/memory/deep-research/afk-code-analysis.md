# Research Memory: AFK Code Analysis

**Date**: 2026-02-05
**Topic**: Remote monitoring and control for autonomous AI coding sessions
**Status**: Completed

## Research Question
How does AFK Code enable unattended Claude Code operation, and what patterns can enhance Jarvis's overnight/autonomous capabilities?

## Key Findings

### Core Architecture
- **PTY Management**: Uses node-pty to spawn Claude in pseudo-terminal, preserving full terminal functionality
- **JSONL Watching**: Hybrid fs.watch() + polling (1s) for reliable conversation monitoring
- **Unix Socket IPC**: Daemon-client architecture for bidirectional communication
- **Snapshot-Based Detection**: Takes filesystem snapshot at session start to handle --continue scenarios
- **Multi-Session Support**: Claimed files tracking prevents conflicts

### Critical Gaps in Jarvis
1. **No remote visibility**: Cannot see what Jarvis is doing without local access
2. **No remote control**: Cannot intervene if Jarvis goes off-track
3. **No error notifications**: Failures could go undetected overnight

### High-Value Features for Jarvis
1. **Remote Monitoring** (Priority 1): Message relay to Telegram—low risk, high value
2. **Bidirectional Control** (Priority 2): Remote command execution with safety controls
3. **Todo/Plan Mode Tracking** (Priority 3): Progress visibility and stall detection
4. **Multi-Session Support** (Priority 4): Run multiple Jarvis instances simultaneously

## Implementation Strategy

### Phase 1: Read-Only Monitoring (1-2 weeks)
- Port session-manager.ts patterns to TypeScript module
- Integrate Telegram bot (grammY library)
- Launch alongside jarvis-watcher in tmux window jarvis:2
- Graceful degradation if monitoring fails

### Phase 2: Remote Control (1-2 weeks)
- PTY wrapper for Claude spawn
- Command whitelist enforcement (/checkpoint, /reflect, /maintain only)
- Audit logging for all remote inputs
- Rate limiting (10 commands/minute)

### Safety Measures
- Command whitelist (no arbitrary code execution)
- Rate limiting (token bucket algorithm)
- Audit logging (append-only, immutable)
- Authentication (Telegram chat ID whitelist)
- Kill switch (signal file to disable remote input)

## Technical Patterns

### Snapshot-Based File Detection
```typescript
// Take snapshot at session start
const initialFileStats = await snapshotJsonlFiles(projectDir);

// Detect modifications (for --continue)
if (initialMtime !== undefined && mtime > initialMtime) {
  return path; // File was modified after session start
}
```

### Hybrid Watching
```typescript
// Event-driven for efficiency
const watcher = watch(projectDir, handleChange);

// Polling for reliability (backup)
setInterval(checkForUpdates, 1000);
```

### PTY + Unix Socket Integration
```typescript
const ptyProcess = pty.spawn('claude-code', [], { cwd });

const daemon = connectToDaemon(sessionId, (text) => {
  ptyProcess.write(text); // Remote input injection
});
```

## Risk Assessment
- **Overall Risk**: LOW to MEDIUM
- **Phase 1 Risk**: LOW (read-only, separate process, graceful failure)
- **Phase 2 Risk**: MEDIUM (input injection requires careful validation)

## Sources
- [AFK Code Repository](https://github.com/clharman/afk-code)
- [Best AI Coding Agents 2026](https://playcode.io/blog/best-ai-coding-agents-2026)
- [Best Practices for AI Agent Implementations 2026](https://onereach.ai/blog/best-practices-for-ai-agent-implementations/)
- [Claude Code Notifications That Don't Suck](https://www.d12frosted.io/posts/2026-01-05-claude-code-notifications)

## Related Research
- Autonomous AI coding agent best practices
- PTY management patterns
- JSONL file watching strategies
- Unix socket IPC for session control

## Next Steps
1. Review full report: `.claude/reports/research/afk-code-analysis-2026-02-05.md`
2. Obtain approval for Phase 1 implementation
3. Set up Telegram bot credentials
4. Begin session-manager.ts port

## Tags
#autonomous #remote-monitoring #pty #jsonl #unix-socket #telegram #safety

# AFK Code Analysis Report

**Date**: 2026-02-05
**Researcher**: Jarvis (Deep Research Agent)
**Scope**: Autonomous/unattended code operation capabilities for potential Jarvis integration

---

## Executive Summary

AFK Code is a TypeScript-based remote monitoring solution for Claude Code sessions, enabling bidirectional communication between local development sessions and remote messaging platforms (Slack, Discord, Telegram). The project demonstrates mature patterns for unattended AI agent operation through PTY (pseudo-terminal) management, JSONL file watching, and Unix socket-based inter-process communication.

**Key Innovation**: Unlike traditional SSH-based remote access, AFK Code creates a transparent monitoring layer that allows developers to supervise and interact with autonomous Claude Code sessions from mobile devices while away from their workstations. The architecture elegantly solves the "observability gap" in long-running AI coding sessions.

**Relevance to Jarvis**: While Jarvis currently has watcher infrastructure (JICM) for context management, it lacks remote notification and bidirectional control mechanisms. AFK Code's architecture offers proven patterns for extending Jarvis's overnight/unattended operation capabilities with minimal integration friction.

---

## Repository Overview

| Metric | Value |
|--------|-------|
| **Stars** | 62 |
| **Forks** | 7 |
| **Language** | TypeScript (100%) |
| **License** | MIT |
| **Latest Version** | v0.3.0 (2026-02-03) |
| **Active Maintenance** | High (last push 2026-02-03) |
| **Documentation Quality** | Excellent (comprehensive README, CLAUDE.md) |
| **Test Coverage** | Not documented |
| **Open Issues** | 0 |

### Maintainer Activity
Colin Harman (@clharman) actively maintains the project with consistent releases. The v0.3.0 release added image/GIF upload support, loading spinners, and bug fixes for Slack/Discord permissions—indicating active feature development and user feedback incorporation.

---

## Architecture Analysis

### Core Components

```
afk-code/
├── src/
│   ├── cli/              # CLI entry points and commands
│   │   ├── index.ts      # Main CLI router
│   │   ├── run.ts        # PTY session spawning + socket client
│   │   ├── slack.ts      # Slack bot launcher
│   │   ├── discord.ts    # Discord bot launcher
│   │   └── telegram.ts   # Telegram bot launcher
│   ├── slack/            # Slack integration
│   │   ├── slack-app.ts       # Bolt app + event handlers
│   │   ├── session-manager.ts # JSONL watcher + Unix socket server
│   │   ├── channel-manager.ts # Channel lifecycle
│   │   └── message-formatter.ts
│   ├── discord/          # Discord integration
│   ├── telegram/         # Telegram integration (grammY)
│   ├── utils/
│   │   └── image-extractor.ts # Path detection + validation
│   └── types/            # Shared TypeScript interfaces
└── slack-manifest.json   # Slack app configuration
```

### Operational Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Messaging Platform                        │
│                  (Slack/Discord/Telegram)                    │
└─────────────────┬───────────────────────────────────────────┘
                  │ Bot API (WebSocket/HTTP)
                  │
         ┌────────▼────────┐
         │   Bot Process   │ (src/{slack,discord,telegram})
         │  (Always-On)    │
         └────────┬────────┘
                  │ Unix Socket (/tmp/afk-code-daemon.sock)
                  │ Bidirectional: messages ↔ input
         ┌────────▼────────┐
         │ Session Manager │ (src/slack/session-manager.ts)
         │  - Unix socket  │
         │  - JSONL watch  │
         │  - Multi-sess   │
         └────────┬────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
  ┌───▼──┐    ┌──▼───┐   ┌──▼───┐
  │ PTY  │    │ PTY  │   │ PTY  │  (node-pty spawned terminals)
  │Session│   │Session│  │Session│
  └───┬──┘    └──┬───┘   └──┬───┘
      │          │          │
  ┌───▼──────────▼──────────▼───┐
  │   Claude Code Instances      │
  │  Write to ~/.claude/projects/│
  │  {encoded-path}/{slug}.jsonl │
  └──────────────────────────────┘
           │
           │ fs.watch() + polling
           │
      ┌────▼────┐
      │  JSONL  │ (conversation logs)
      │ Watcher │
      └─────────┘
```

### Key Design Patterns

#### 1. PTY Management (src/cli/run.ts)
- Uses `node-pty` to spawn Claude Code in a pseudo-terminal
- Preserves full terminal features (colors, interactive prompts)
- Forwards stdin/stdout bidirectionally
- Handles terminal resize events
- **Innovation**: Combines PTY with Unix socket for remote input injection

```typescript
// Simplified pattern from run.ts
const ptyProcess = pty.spawn(command[0], command.slice(1), {
  name: 'xterm-256color',
  cols, rows, cwd,
  env: process.env
});

// Connect to daemon for remote input
const daemon = await connectToDaemon(sessionId, projectDir, cwd, command, 
  (text) => ptyProcess.write(text)  // Remote input injection
);
```

#### 2. JSONL Watching (src/slack/session-manager.ts)
Sophisticated multi-strategy approach:

**a) Snapshot-based Detection**
- Takes filesystem snapshot at session start
- Tracks existing files' mtimes
- Detects both new files AND modified files (for `--continue` scenarios)
- Solves the "which conversation file?" problem for multi-session scenarios

```typescript
// Snapshot existing files before session starts
const initialFileStats = await this.snapshotJsonlFiles(projectDir);

// Later: detect modifications
if (initialMtime !== undefined && mtime > initialMtime) {
  // Existing file modified (--continue case)
  return path;
}
```

**b) Content Validation**
- Doesn't just look at filenames—validates actual conversation content
- Checks for `"type":"user"` or `"type":"assistant"` presence
- Filters out metadata-only files
- Prevents false positives from agent logs

**c) Hybrid Watching**
- Uses `fs.watch()` for event-driven updates (efficient)
- Fallback polling every 1s (reliable)
- This dual approach handles edge cases where fs.watch() misses events

**d) Multi-Session Safety**
- Maintains `claimedFiles` set to prevent conflicts
- Multiple sessions can run simultaneously without interference
- Each bot instance can track separate conversations

#### 3. Unix Socket IPC
- Daemon-client architecture using `/tmp/afk-code-daemon.sock`
- Newline-delimited JSON protocol
- Session lifecycle messages: `session_start`, `session_end`, `input`
- Graceful degradation: if socket connection fails, session runs without monitoring

#### 4. Message Extraction
From JSONL files, extracts:
- **Chat messages**: user/assistant content blocks
- **Session slug**: for human-readable naming
- **Tool calls**: tracks which tools Claude invoked (though not relayed to avoid rate limits)
- **Tool results**: captures output/errors
- **Todos**: active TodoWrite task lists
- **Plan mode status**: detects when Claude enters/exits planning mode
- **Timestamp filtering**: ignores messages from before session start (critical for `--continue`)

#### 5. Image Detection (src/utils/image-extractor.ts)
Regex-based path extraction with validation:
- Matches quoted and unquoted paths: `/path/file.png`, `"./relative.jpg"`, `~/home.gif`
- Supports all common formats: PNG, JPG, GIF, WebP, SVG, etc.
- Resolves relative paths (`./`, `../`), home paths (`~/`), and absolute paths
- Validates existence and file type before upload
- Prevents false positives from random strings

---

## Feature Inventory

### Core Features

| Feature | Description | Jarvis Equivalent | Gap Analysis |
|---------|-------------|-------------------|--------------|
| **Remote Monitoring** | Relay Claude messages to chat platform | None | HIGH GAP: No remote visibility |
| **Bidirectional Control** | Send input to Claude from mobile | None | HIGH GAP: Cannot interact remotely |
| **Multi-Session Support** | Track multiple Claude instances | Partial (JICM single session) | MEDIUM GAP: No multi-session |
| **Image Auto-Upload** | Detect and upload referenced images | None | LOW GAP: Nice-to-have |
| **Slash Commands** | `/sessions`, `/model`, `/compact`, `/interrupt`, `/background`, `/mode` | Partial (native commands) | MEDIUM GAP: No remote commands |
| **Plan Mode Detection** | Alert when Claude enters planning mode | None | MEDIUM GAP: Reduces intervention |
| **Session Naming** | Extract slug for human-readable names | None | LOW GAP: Cosmetic |
| **Todo Tracking** | Monitor TodoWrite tasks | None | MEDIUM GAP: Progress visibility |
| **Platform Flexibility** | Telegram/Discord/Slack support | None | LOW GAP: Single platform sufficient |

### Advanced Capabilities

| Capability | Implementation | Value for Jarvis |
|------------|----------------|------------------|
| **Graceful Degradation** | Runs without daemon if socket unavailable | HIGH: Robustness pattern |
| **Continue Support** | Detects modified files for `--continue` sessions | HIGH: Critical for long-running work |
| **Timestamp Filtering** | Ignores pre-session messages | HIGH: Prevents confusion in resumed sessions |
| **Loading Feedback** | Spinner during startup | LOW: UX polish |
| **Model Switching** | Remote model change commands | MEDIUM: Useful for cost management |
| **Interrupt Handling** | Send Escape/Ctrl+B remotely | HIGH: Critical for runaway sessions |

---

## Key Innovations

### 1. Transparent Session Monitoring
AFK Code doesn't modify Claude Code or require special configurations. It works by:
- Spawning Claude in a PTY (preserving all functionality)
- Watching standard JSONL logs (no proprietary formats)
- Using Unix sockets for loose coupling (daemon can restart independently)

**Why This Matters**: Drop-in compatibility means zero risk of breaking Claude Code behavior. Jarvis could adopt the same pattern without architectural changes.

### 2. Mobile-First Remote Control
Unlike SSH-based solutions, AFK Code brings Claude conversations into messaging apps:
- **Siri integration** (Telegram): Voice commands to send input
- **Push notifications**: Immediate alerts when Claude responds
- **Rich media**: Images inline, not just paths
- **Async-friendly**: No need to maintain SSH connection

**Why This Matters**: True "away from keyboard" operation requires mobile convenience. Desktop-only monitoring defeats the purpose.

### 3. Snapshot-Based File Detection
Most file watchers naively glob for `*.jsonl`. AFK Code's snapshot approach:
- Handles the `--continue` edge case (modified existing file)
- Prevents claiming wrong sessions in multi-user scenarios
- Validates conversation content (not just filename patterns)

**Why This Matters**: Robust file detection is the foundation of reliable monitoring. This pattern is production-ready.

### 4. Hybrid Watch Strategy
Combining `fs.watch()` + polling:
- Event-driven for efficiency (low CPU)
- Polling for reliability (catches missed events)
- Configurable intervals (1s default balances latency/overhead)

**Why This Matters**: Filesystem watchers are notoriously unreliable across platforms. The hybrid approach ensures messages are never missed.

---

## Comparison to Jarvis

### Current Jarvis Capabilities

From the codebase analysis, Jarvis has:

| Component | Purpose | Strengths | Limitations |
|-----------|---------|-----------|-------------|
| **jarvis-watcher.sh** | Context monitoring (JICM) | Single-purpose, stable, tmux-integrated | No remote notifications, no bidirectional control |
| **Signal files** | Trigger compression cycles | Simple, reliable | Not exposed remotely |
| **tmux integration** | Background operation | Persistent sessions | Local-only interaction |
| **Idle-hands** | Auto-wake on session start | Autonomous initialization | No mid-session intervention |
| **Native commands** | Autonomous operations | Signal-based execution | Requires local access to trigger |

### Gap Analysis

#### HIGH Priority Gaps

1. **No Remote Visibility**
   - **Problem**: Cannot see what Jarvis is doing without local access
   - **Impact**: Defeats "overnight operation" use case if you can't check progress
   - **AFK Solution**: Real-time message relay to messaging platform

2. **No Remote Control**
   - **Problem**: Cannot intervene if Jarvis goes off-track
   - **Impact**: Autonomous operation is risky without escape hatch
   - **AFK Solution**: Bidirectional input via Unix socket + PTY injection

3. **No Error Notifications**
   - **Problem**: Jarvis could fail silently overnight
   - **Impact**: Wasted time, blocked progress
   - **AFK Solution**: Push notifications on critical events (plan mode, todos, errors)

#### MEDIUM Priority Gaps

4. **No Multi-Session Support**
   - **Problem**: JICM assumes single session in working directory
   - **Impact**: Cannot run multiple Jarvis instances simultaneously
   - **AFK Solution**: Session manager with claimed files tracking

5. **No Todo Progress Tracking**
   - **Problem**: TodoWrite creates tasks, but no visibility into completion
   - **Impact**: Hard to estimate remaining work
   - **AFK Solution**: Extracts and relays todo status changes

6. **No Plan Mode Alerts**
   - **Problem**: Claude entering plan mode blocks progress
   - **Impact**: Session stalls until manually exited
   - **AFK Solution**: Detects plan mode entry, sends alert, allows remote `/mode` command

#### LOW Priority Gaps

7. **No Session Naming**
   - **Problem**: Sessions identified by directory path only
   - **Impact**: Hard to distinguish in logs
   - **AFK Solution**: Extracts slug from JSONL for human-readable names

8. **No Image Upload**
   - **Problem**: Screenshot references are just paths in notifications
   - **Impact**: Cannot view images without local access
   - **AFK Solution**: Detects image paths, uploads to chat

---

## Implementation Recommendations

### Priority 1: Remote Monitoring Foundation (HIGH VALUE, LOW RISK)

**Objective**: Enable remote visibility into Jarvis sessions via messaging platform.

| Component | Effort | Dependencies | Risk |
|-----------|--------|--------------|------|
| JSONL watcher module | 2-3 days | None | LOW: Read-only, no Claude interaction |
| Session manager (Unix socket server) | 2-3 days | JSONL watcher | LOW: Separate process, graceful failure |
| Telegram bot integration | 2-3 days | Session manager | LOW: Bot SDKs are mature (grammY) |
| Basic message relay | 1 day | All above | LOW: Display-only functionality |

**Total Estimated Effort**: 1-1.5 weeks

**Implementation Strategy**:
1. Extract session-manager.ts patterns into Jarvis module
2. Integrate with existing jarvis-watcher.sh or run as separate process
3. Create `.claude/scripts/jarvis-remote-monitor.ts` (Node.js process)
4. Add Telegram bot credentials to `.claude/config/`
5. Launch alongside watcher in tmux window `jarvis:2`

**Safety Considerations**:
- Read-only initially (no input injection)
- Run in separate process (can crash without affecting Jarvis)
- Use existing JSONL files (no Claude Code modifications)
- Graceful degradation if monitoring fails

**Validation Checklist**:
- [ ] Telegram bot receives Jarvis messages in real-time
- [ ] Multiple messages relay correctly (no drops)
- [ ] Session start/end events detected
- [ ] Bot restarts don't lose messages (polling fallback)
- [ ] Works with `--continue` sessions

---

### Priority 2: Remote Control (HIGH VALUE, MEDIUM RISK)

**Objective**: Enable bidirectional interaction—send commands to Jarvis from mobile.

| Component | Effort | Dependencies | Risk |
|-----------|--------|--------------|------|
| PTY wrapper for Claude spawn | 2-3 days | Priority 1 complete | MEDIUM: PTY stability critical |
| Input injection via Unix socket | 1-2 days | PTY wrapper | MEDIUM: Race conditions possible |
| Command whitelist/validation | 1-2 days | Input injection | HIGH: Security-critical |
| Slash command handlers | 2-3 days | All above | LOW: Application logic |

**Total Estimated Effort**: 1-1.5 weeks

**Implementation Strategy**:
1. Replace direct `claude-code` invocation with PTY-wrapped version
2. Connect PTY to session manager's Unix socket
3. Implement command validation (whitelist approved commands)
4. Add safety timeout (5s delay before destructive commands)
5. Log all remote inputs for audit trail

**Safety Considerations**:
- **Command whitelist**: Only allow safe commands (`/checkpoint`, `/reflect`, model switching)
- **No arbitrary code execution**: Block shell commands, only Claude commands
- **Audit logging**: Every remote input logged to `.claude/logs/remote-inputs.log`
- **Rate limiting**: Max 10 commands/minute to prevent abuse
- **Session binding**: Commands must target specific session by ID

**Validation Checklist**:
- [ ] Remote `/checkpoint` triggers successfully
- [ ] Invalid commands rejected
- [ ] Audit log captures all remote inputs
- [ ] Rate limiting prevents spam
- [ ] PTY stays stable under load

**Risk Mitigation**:
- Start with read-only monitoring for 1 week in production
- Enable input injection only after stability validation
- Implement emergency kill switch (signal file to disable remote input)
- Test extensively in non-critical sessions

---

### Priority 3: Advanced Features (MEDIUM VALUE, LOW RISK)

**Objective**: Enhance observability with todos, plan mode detection, images.

| Component | Effort | Dependencies | Risk |
|-----------|--------|--------------|------|
| Todo extraction | 1 day | Priority 1 | LOW: Read-only data extraction |
| Plan mode detection | 1 day | Priority 1 | LOW: Regex-based detection |
| Image path extraction | 1-2 days | Priority 1 | LOW: Filesystem reads only |
| Image upload to Telegram | 1 day | Image extraction | LOW: Bot API stable |
| Model switching command | 1 day | Priority 2 | LOW: Simple state change |

**Total Estimated Effort**: 5-7 days

**Implementation Strategy**:
1. Reuse AFK Code's extraction patterns (BSD-compatible license: MIT)
2. Add todo/plan mode handlers to session manager
3. Integrate image-extractor.ts into Jarvis utils
4. Configure Telegram bot for file uploads (requires `files:write` scope)
5. Add `/model` command to slash command handlers

**Safety Considerations**:
- Image uploads require path validation (no arbitrary file reads)
- Todo extraction is informational only (no side effects)
- Plan mode alerts don't auto-exit (user must confirm)

**Validation Checklist**:
- [ ] Todos update in real-time as tasks complete
- [ ] Plan mode alerts fire when detected
- [ ] Images upload successfully (PNG, JPG, GIF)
- [ ] Model switch command works across opus/sonnet/haiku
- [ ] No performance degradation from feature overhead

---

### Priority 4: Multi-Session Support (MEDIUM VALUE, MEDIUM RISK)

**Objective**: Run multiple Jarvis instances concurrently with independent monitoring.

| Component | Effort | Dependencies | Risk |
|-----------|--------|--------------|------|
| Claimed files tracking | 1-2 days | Session manager | LOW: Data structure only |
| Session ID generation | 0.5 day | None | LOW: UUID library |
| Multi-session UI in Telegram | 2-3 days | Session manager | MEDIUM: State management |
| `/switch` command | 1-2 days | Multi-session UI | LOW: Session router |

**Total Estimated Effort**: 4-7 days

**Implementation Strategy**:
1. Extend session manager with `claimedFiles: Set<string>`
2. Assign UUIDs to each session on start
3. Store session metadata in `.claude/state/sessions/{id}.json`
4. Telegram bot shows active sessions with `/sessions` command
5. `/switch <id>` changes active session for that chat

**Safety Considerations**:
- File claiming prevents race conditions (sessions don't overlap)
- Session IDs namespace state cleanly (no cross-contamination)
- Stale session cleanup after 24h idle (prevents resource leaks)

**Validation Checklist**:
- [ ] Two Jarvis instances run simultaneously without interference
- [ ] `/sessions` lists all active sessions
- [ ] `/switch` changes which session receives commands
- [ ] Session cleanup runs on schedule
- [ ] No JSONL file conflicts observed

---

## Detailed Implementation Plan

### Phase 1: Foundation (Week 1-2)

**Goal**: Read-only remote monitoring with zero risk to existing Jarvis functionality.

#### Step 1: Setup Infrastructure
```bash
# Install dependencies
cd /Users/aircannon/Claude/Jarvis
npm install grammy node-pty @types/node

# Create directory structure
mkdir -p .claude/remote/
mkdir -p .claude/config/telegram/

# Create config file
cat > .claude/config/telegram/credentials.json << 'EOF'
{
  "botToken": "TELEGRAM_BOT_TOKEN",
  "chatId": "YOUR_CHAT_ID"
}
EOF
```

#### Step 2: Port Session Manager
```bash
# Create TypeScript module
touch .claude/remote/session-manager.ts
touch .claude/remote/jsonl-watcher.ts
touch .claude/remote/telegram-bot.ts

# Copy and adapt AFK Code patterns:
# - session-manager.ts: snapshotJsonlFiles(), findActiveJsonlFile()
# - jsonl-watcher.ts: processJsonlUpdates(), parseJsonlLine()
# - telegram-bot.ts: grammY bot setup, message relay
```

#### Step 3: Integration with Jarvis
```bash
# Create launcher script
touch .claude/scripts/launch-remote-monitor.sh

# Script content:
#!/bin/bash
cd /Users/aircannon/Claude/Jarvis
node --loader ts-node/esm .claude/remote/telegram-bot.ts

# Add to jarvis-watcher.sh or run in separate tmux window
tmux new-window -t jarvis:2 -n monitor \
  'bash .claude/scripts/launch-remote-monitor.sh'
```

#### Step 4: Testing
1. Start Jarvis in test project
2. Verify Telegram bot receives messages
3. Test session end detection
4. Validate `--continue` support
5. Confirm no interference with JICM

**Exit Criteria**:
- [ ] Telegram bot shows Jarvis messages in real-time
- [ ] No message drops observed in 8-hour session
- [ ] JICM context management unaffected
- [ ] Process crashes don't affect Jarvis core

---

### Phase 2: Bidirectional Control (Week 3-4)

**Goal**: Enable remote input with strict safety controls.

#### Step 1: PTY Wrapper
```typescript
// .claude/remote/pty-claude.ts
import * as pty from 'node-pty';

export function spawnClaude(cwd: string, sessionId: string) {
  const ptyProcess = pty.spawn('claude-code', [], {
    name: 'xterm-256color',
    cols: 80,
    rows: 24,
    cwd,
    env: process.env as Record<string, string>,
  });

  // Connect to daemon for remote input
  const daemon = connectToSessionManager(sessionId, (text) => {
    ptyProcess.write(text);
  });

  return { ptyProcess, daemon };
}
```

#### Step 2: Command Validation
```typescript
// .claude/remote/command-validator.ts
const SAFE_COMMANDS = new Set([
  '/checkpoint',
  '/reflect',
  '/maintain',
  '/tooling-health',
  '/end-session'
]);

const SAFE_PATTERNS = [
  /^\/model (opus|sonnet|haiku)$/,
  /^\/compact$/,
  /^\/background$/,
  /^\/interrupt$/,
];

export function validateCommand(input: string): boolean {
  if (SAFE_COMMANDS.has(input)) return true;
  return SAFE_PATTERNS.some(p => p.test(input));
}
```

#### Step 3: Audit Logging
```typescript
// Log every remote input
function logRemoteInput(sessionId: string, input: string, source: string) {
  const timestamp = new Date().toISOString();
  const logEntry = { timestamp, sessionId, input, source };
  
  fs.appendFileSync(
    '/Users/aircannon/Claude/Jarvis/.claude/logs/remote-inputs.log',
    JSON.stringify(logEntry) + '\n'
  );
}
```

#### Step 4: Rate Limiting
```typescript
// Simple token bucket rate limiter
class RateLimiter {
  private tokens = 10;
  private maxTokens = 10;
  private refillRate = 10 / 60000; // 10 per minute

  canExecute(): boolean {
    this.refill();
    if (this.tokens >= 1) {
      this.tokens--;
      return true;
    }
    return false;
  }

  private refill() {
    const now = Date.now();
    const elapsed = now - this.lastRefill;
    this.tokens = Math.min(
      this.maxTokens,
      this.tokens + elapsed * this.refillRate
    );
    this.lastRefill = now;
  }
}
```

**Exit Criteria**:
- [ ] Remote commands execute successfully
- [ ] Invalid commands rejected with error message
- [ ] All inputs logged to audit trail
- [ ] Rate limiter prevents spam (tested with 20 rapid commands)
- [ ] PTY stable after 24h operation

---

### Phase 3: Advanced Features (Week 5)

#### Step 1: Todo Extraction
```typescript
// Reuse AFK pattern from session-manager.ts
private extractTodos(line: string): TodoItem[] | null {
  try {
    const data = JSON.parse(line);
    if (data.todos && Array.isArray(data.todos)) {
      return data.todos.map(t => ({
        content: t.content || '',
        status: t.status || 'pending',
        activeForm: t.activeForm,
      }));
    }
  } catch {}
  return null;
}
```

#### Step 2: Plan Mode Detection
```typescript
// Detect from system reminders in JSONL
private detectPlanMode(line: string): boolean | null {
  try {
    const data = JSON.parse(line);
    if (data.type !== 'user') return null;
    
    const content = data.message?.content;
    if (typeof content !== 'string') return null;
    
    if (content.includes('Plan mode is active')) return true;
    if (content.includes('exited plan mode')) return false;
  } catch {}
  return null;
}
```

#### Step 3: Image Upload
```typescript
// Adapt image-extractor.ts
import { extractImagePaths } from '.claude/remote/utils/image-extractor';

async function handleMessage(sessionId: string, content: string) {
  // Send text message
  await bot.sendMessage(chatId, content);
  
  // Check for images
  const images = extractImagePaths(content, session.cwd);
  for (const img of images) {
    await bot.sendPhoto(chatId, {
      source: img.resolvedPath,
      caption: img.originalPath,
    });
  }
}
```

**Exit Criteria**:
- [ ] Todos display in Telegram with status indicators
- [ ] Plan mode entry triggers notification
- [ ] Images upload successfully (tested with PNG/JPG/GIF)
- [ ] No false positives on image detection

---

### Phase 4: Production Hardening (Week 6)

#### Error Handling
```typescript
// Graceful degradation
try {
  await sessionManager.start();
} catch (err) {
  console.error('[Jarvis Remote] Failed to start, running local-only:', err);
  // Continue without remote monitoring
}
```

#### Health Checks
```typescript
// Periodic health check
setInterval(() => {
  const sessions = sessionManager.getAllSessions();
  console.log(`[Jarvis Remote] Active sessions: ${sessions.length}`);
  
  // Cleanup stale sessions
  for (const session of sessions) {
    const age = Date.now() - session.startedAt.getTime();
    if (age > 24 * 60 * 60 * 1000 && session.status === 'idle') {
      sessionManager.stopSession(session.id);
    }
  }
}, 60000);
```

#### Monitoring Metrics
```json
// .claude/logs/remote-monitor-metrics.json
{
  "timestamp": "2026-02-05T10:30:00Z",
  "sessions": {
    "active": 1,
    "total": 5,
    "avg_duration_hours": 3.2
  },
  "messages": {
    "relayed": 1243,
    "dropped": 0,
    "latency_ms": 45
  },
  "commands": {
    "executed": 12,
    "rejected": 3,
    "rate_limited": 0
  }
}
```

**Exit Criteria**:
- [ ] Crashes don't affect Jarvis core (tested with kill -9)
- [ ] Health checks detect and clean stale sessions
- [ ] Metrics logged every 5 minutes
- [ ] 48-hour stability test passed (no memory leaks, no crashes)

---

## Safety Considerations

### Security Layers

1. **Command Whitelist** (PRIMARY DEFENSE)
   - Only approved commands can execute remotely
   - Blocklist includes: shell commands, file operations, git force operations
   - Reviewed and approved by human before enabling

2. **Rate Limiting** (ABUSE PREVENTION)
   - Token bucket algorithm: 10 commands/minute max
   - Prevents accidental spam and malicious flooding
   - Per-session limits (not global)

3. **Audit Logging** (ACCOUNTABILITY)
   - Every remote input logged with timestamp, session ID, source
   - Logs immutable (append-only)
   - Reviewed periodically for anomalies

4. **Authentication** (ACCESS CONTROL)
   - Telegram bot token kept in `.claude/config/` (gitignored)
   - Chat ID whitelist (only specific users can send commands)
   - No public bot access

5. **Graceful Failure** (ROBUSTNESS)
   - Remote monitoring crashes don't affect Jarvis
   - Socket connection failures fall back to local-only operation
   - PTY errors trigger session cleanup (no zombie processes)

### Operational Safety

1. **Kill Switch**
   - Signal file: `.claude/remote/.disabled`
   - If present, remote input injection is blocked
   - Enable via: `touch .claude/remote/.disabled`

2. **Destructive Command Protection**
   - Commands like `/end-session` require confirmation
   - 5-second delay with cancel option
   - Warning displayed in Telegram before execution

3. **Session Isolation**
   - Each session has independent state
   - File claiming prevents cross-session interference
   - Session IDs namespace all operations

4. **Rollback Plan**
   - Remote monitor runs in separate process (can be killed)
   - Disable by removing from watcher launch script
   - No changes to core Jarvis files (drop-in, drop-out)

### Testing Strategy

1. **Unit Tests**
   - Command validator (whitelist/blocklist)
   - Rate limiter (token bucket logic)
   - Image path extractor (regex edge cases)

2. **Integration Tests**
   - End-to-end message relay (Jarvis → Telegram → Jarvis)
   - Session lifecycle (start, continue, end)
   - Multi-session scenarios (3+ concurrent)

3. **Stress Tests**
   - 100 commands/second (verify rate limiting)
   - 24-hour continuous operation (memory leaks)
   - Rapid session churn (start/stop 50 sessions)

4. **Failure Mode Tests**
   - Network disconnection (does PTY survive?)
   - Bot process crash (does Jarvis continue?)
   - JSONL file corruption (does parser recover?)

---

## Risks and Mitigations

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PTY instability crashes Jarvis | LOW | HIGH | Run PTY in separate process, implement watchdog |
| JSONL parsing fails on malformed input | MEDIUM | LOW | Try-catch all JSON.parse, skip bad lines |
| fs.watch() misses events | MEDIUM | MEDIUM | Hybrid watch + polling (1s interval) |
| Unix socket permission issues | LOW | MEDIUM | Hardcode socket path, set 0777 permissions |
| Rate limiter bypassed | LOW | LOW | Multiple enforcement layers (bot + session manager) |

### Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Bot token leaked | LOW | HIGH | Store in `.gitignore`d config, rotate if exposed |
| Unauthorized command execution | LOW | HIGH | Whitelist + chat ID authentication |
| Message flood from runaway loop | MEDIUM | MEDIUM | Rate limiting + flood detection (>10 msg/sec) |
| Session state desync | MEDIUM | MEDIUM | Periodic state reconciliation from JSONL |
| Stale sessions accumulate | LOW | LOW | Cleanup cron job (24h idle → terminate) |

### Integration Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| JICM conflicts with remote monitor | LOW | HIGH | Monitor reads same files, no writes |
| Context exhaustion not detected | LOW | MEDIUM | Remote monitor also watches token usage |
| Signal file race conditions | LOW | LOW | Atomic file operations (rename, not write) |
| tmux session interference | LOW | LOW | Use dedicated window (jarvis:2) |

---

## Alternative Approaches Considered

### 1. SSH-Based Remote Access
**Pros**: No bot infrastructure, uses standard protocols
**Cons**: Requires open SSH port, no push notifications, mobile-unfriendly
**Decision**: Rejected—messaging platforms offer superior mobile UX

### 2. Direct Claude Code Modification
**Pros**: Could intercept messages at source
**Cons**: Breaks on Claude updates, violates "no modification" principle
**Decision**: Rejected—JSONL watching is non-invasive

### 3. Webhook-Based Notifications
**Pros**: Simpler than bot architecture, no persistent connection
**Cons**: No bidirectional control, requires public endpoint
**Decision**: Rejected—bot offers richer feature set

### 4. File-Based IPC (instead of Unix sockets)
**Pros**: No socket permissions issues
**Cons**: Slower, harder to clean up, race conditions
**Decision**: Rejected—Unix sockets are purpose-built for IPC

### 5. Integrate into jarvis-watcher.sh (bash)
**Pros**: Single process, simpler deployment
**Cons**: Bash HTTP clients are painful, no good JSONL parsing
**Decision**: Rejected—TypeScript offers better libraries (grammY, node-pty)

---

## References

### Primary Sources
1. [AFK Code Repository](https://github.com/clharman/afk-code) - Main project source
2. [AFK Code v0.3.0 Release](https://github.com/clharman/afk-code/releases/tag/v0.3.0) - Latest release notes
3. [CLAUDE.md](https://raw.githubusercontent.com/clharman/afk-code/main/CLAUDE.md) - Project architecture docs

### Supporting Research
4. [Best AI Coding Agents 2026](https://playcode.io/blog/best-ai-coding-agents-2026) - Autonomous coding trends
5. [Best Practices for AI Agent Implementations: Enterprise Guide 2026](https://onereach.ai/blog/best-practices-for-ai-agent-implementations/) - Security and governance frameworks
6. [Top 8 Autonomous Coding Solutions for Developers 2026](https://zencoder.ai/blog/best-autonomous-coding-solutions) - Comparison of autonomous coding tools
7. [AI Agents in Software Development 2026: The Complete Guide to Agentic AI](https://senorit.de/en/blog/ai-agents-software-development-2026) - Agentic AI patterns
8. [From automation to autonomy: The dawn of the agentic MSP](https://managedservicesjournal.com/articles/best-practices/from-automation-to-autonomy-the-dawn-of-the-agentic-msp/) - Control boundaries and governance

### Technical References
9. [Claude Code Usage Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) - Alternative monitoring approach
10. [Claude Code Notifications That Don't Suck](https://www.d12frosted.io/posts/2026-01-05-claude-code-notifications) - Notification patterns
11. [A complete guide to monitoring Claude Code in 2025](https://www.eesel.ai/blog/monitoring-claude-code) - Monitoring best practices
12. [Monitor Claude Code adoption with Datadog](https://www.datadoghq.com/blog/claude-code-monitoring/) - Enterprise monitoring
13. [Desktop Notifications for Claude Code](https://kane.mx/posts/2025/claude-code-notification-hooks/) - OSC escape sequences

### PTY and IPC References
14. [node-pty GitHub](https://github.com/microsoft/node-pty) - PTY library documentation
15. [PTY(7) Linux Manual](https://man7.org/linux/man-pages/man7/pty.7.html) - Pseudo-terminal fundamentals
16. [Using pseudo-terminals to control interactive programs](http://www.rkoucha.fr/tech_corner/pty_pdip.html) - PTY patterns

---

## Appendices

### Appendix A: Code Snippets

#### Minimal Working Example: JSONL Watcher
```typescript
import { watch } from 'fs';
import { readFile } from 'fs/promises';

async function watchSession(projectDir: string) {
  const seenMessages = new Set<string>();
  
  const watcher = watch(projectDir, async (_, filename) => {
    if (!filename?.endsWith('.jsonl')) return;
    
    const content = await readFile(`${projectDir}/${filename}`, 'utf-8');
    const lines = content.split('\n').filter(Boolean);
    
    for (const line of lines) {
      if (seenMessages.has(line)) continue;
      seenMessages.add(line);
      
      try {
        const data = JSON.parse(line);
        if (data.type === 'assistant' && data.message?.content) {
          console.log('ASSISTANT:', data.message.content);
        }
      } catch {}
    }
  });
  
  return watcher;
}
```

#### Minimal Working Example: Telegram Bot
```typescript
import { Bot } from 'grammy';

const bot = new Bot('YOUR_BOT_TOKEN');
const CHAT_ID = 'YOUR_CHAT_ID';

bot.command('ping', (ctx) => ctx.reply('Pong!'));

bot.on('message:text', async (ctx) => {
  if (ctx.chat.id.toString() !== CHAT_ID) return;
  
  const input = ctx.message.text;
  console.log('Received from Telegram:', input);
  
  // Send to Jarvis via Unix socket here
});

bot.start();
```

---

### Appendix B: File Locations Reference

```
/Users/aircannon/Claude/Jarvis/
├── .claude/
│   ├── remote/                          # New: Remote monitoring
│   │   ├── session-manager.ts           # Unix socket server + JSONL watcher
│   │   ├── telegram-bot.ts              # Telegram bot + message relay
│   │   ├── pty-claude.ts                # PTY wrapper for Claude spawn
│   │   ├── command-validator.ts         # Whitelist enforcement
│   │   └── utils/
│   │       └── image-extractor.ts       # Image path detection
│   ├── scripts/
│   │   ├── jarvis-watcher.sh            # Existing: JICM watcher
│   │   └── launch-remote-monitor.sh     # New: Start remote monitor
│   ├── config/
│   │   └── telegram/
│   │       └── credentials.json         # Bot token + chat ID (gitignored)
│   ├── logs/
│   │   ├── remote-inputs.log            # Audit trail for remote commands
│   │   └── remote-monitor-metrics.json  # Health metrics
│   └── state/
│       └── sessions/                    # Multi-session metadata
│           └── {session-id}.json
└── /tmp/
    └── jarvis-remote.sock               # Unix socket for IPC
```

---

### Appendix C: Configuration Template

```json
// .claude/config/telegram/credentials.json
{
  "botToken": "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz",
  "chatId": "123456789",
  "features": {
    "messageRelay": true,
    "remoteControl": false,    // Enable after testing
    "imageUpload": true,
    "todoTracking": true,
    "planModeAlerts": true
  },
  "safety": {
    "commandWhitelist": [
      "/checkpoint",
      "/reflect",
      "/maintain"
    ],
    "rateLimit": {
      "maxCommands": 10,
      "windowMs": 60000
    },
    "requireConfirmation": [
      "/end-session"
    ]
  }
}
```

---

### Appendix D: Testing Checklist

#### Phase 1: Read-Only Monitoring
- [ ] Telegram bot starts successfully
- [ ] Messages relay within 1 second
- [ ] Session start/end detected
- [ ] JSONL watcher stable for 8+ hours
- [ ] `--continue` sessions work correctly
- [ ] No JICM interference observed
- [ ] Process crash doesn't affect Jarvis

#### Phase 2: Bidirectional Control
- [ ] Remote `/checkpoint` executes
- [ ] Invalid commands rejected
- [ ] Rate limiter blocks >10 commands/minute
- [ ] Audit log complete and accurate
- [ ] PTY stable after 24 hours
- [ ] Confirmation prompts work
- [ ] Kill switch disables input

#### Phase 3: Advanced Features
- [ ] Todos update in real-time
- [ ] Plan mode alerts fire
- [ ] Images upload (PNG, JPG, GIF)
- [ ] Model switching works
- [ ] No false positives on image detection

#### Phase 4: Production Readiness
- [ ] 48-hour stability test passed
- [ ] Memory usage stable (<100MB)
- [ ] Stale session cleanup works
- [ ] Health metrics logged
- [ ] Rollback procedure tested
- [ ] Documentation complete

---

## Conclusion

AFK Code provides a mature, production-ready pattern for remote monitoring and control of autonomous AI coding sessions. Its architecture—PTY management, JSONL watching, Unix socket IPC, and messaging platform integration—directly addresses Jarvis's current gaps in unattended operation visibility and control.

**Recommended Path Forward**:
1. **Week 1-2**: Implement read-only monitoring (Priority 1)—low risk, high value
2. **Week 3**: Validate stability in production for 7 days before proceeding
3. **Week 4-5**: Implement bidirectional control (Priority 2) with strict safety measures
4. **Week 6**: Add advanced features (Priority 3) and production hardening (Priority 4)

**Expected Outcomes**:
- Remote visibility into overnight Jarvis operations
- Mobile intervention capability for runaway sessions
- Reduced time-to-recovery from failures
- Increased confidence in autonomous operation

**Total Estimated Effort**: 4-6 weeks full-time equivalent (can be done incrementally)

**Risk Assessment**: LOW to MEDIUM—architecture is proven, implementation is well-scoped, safety measures are comprehensive.

---

**Report Completed**: 2026-02-05
**Next Actions**: 
1. Review report with stakeholders
2. Obtain approval for Phase 1 implementation
3. Set up Telegram bot credentials
4. Begin session-manager.ts port

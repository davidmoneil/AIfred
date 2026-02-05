# AIfred Hooks

Automatic behaviors that run before/after tool executions.

**Last Updated**: 2026-02-05
**Total Hooks**: 32 (26 existing + 6 new from v2.1 sync)

---

## Installed Hooks

### Lifecycle Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.js` | SessionStart | Auto-load context on startup |
| `session-stop.js` | Stop | Desktop notification when done |
| `subagent-stop.js` | SubagentStop | Agent chaining & activity logging |
| `pre-compact.js` | PreCompact | Preserve context before compaction |
| `self-correction-capture.js` | UserPromptSubmit | Detect corrections, save lessons |
| `worktree-manager.js` | PostToolUse | Track worktrees, warn cross-access |
| `orchestration-detector.js` | UserPromptSubmit | Score task complexity, trigger orchestration |
| `cross-project-commit-tracker.js` | PostToolUse | Track commits across multiple projects |

### Core Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `audit-logger.js` | PreToolUse | Log all tool executions + pattern detection |
| `session-tracker.js` | Notification | Track session lifecycle |
| `session-exit-enforcer.js` | PostToolUse | Track activity for exit |
| `context-reminder.js` | PostToolUse | Prompt for documentation |
| `docker-health-check.js` | PostToolUse | Verify container health |
| `memory-maintenance.js` | PostToolUse | Track Memory MCP entity access |
| `file-access-tracker.js` | PostToolUse | Track context file usage patterns |
| `health-monitor.js` | PostToolUse | Track service health changes |
| `restart-loop-detector.js` | PostToolUse | Detect container restart loops |

### Security Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `secret-scanner.js` | PreToolUse | Block commits with secrets |
| `branch-protection.js` | PreToolUse | Protect main/master branches |
| `credential-guard.js` | PreToolUse | Block reading sensitive files |
| `amend-validator.js` | PreToolUse | Block amending others' commits |

### Workflow Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `prompt-enhancer.js` | UserPromptSubmit | Inject LSP/MCP guidance |
| `lsp-redirector.js` | PreToolUse | Redirect Grep to LSP tool |
| `doc-sync-trigger.js` | PostToolUse | Track code changes, suggest sync |
| `skill-router.js` | UserPromptSubmit | Route commands to parent skills for context |
| `planning-mode-detector.js` | UserPromptSubmit | Auto-detect when planning is needed |
| `priority-validator.js` | PostToolUse | Track evidence for priority completion |
| `compose-validator.js` | PreToolUse | Validate docker-compose before deployment |
| `context-usage-tracker.js` | PreToolUse | Estimate token/context usage per session |
| `index-sync.js` | PostToolUse | Keep _index.md files in sync |
| `project-detector.js` | UserPromptSubmit | Auto-detect and register projects |

---

## Pattern Detection (audit-logger.js)

The audit-logger now detects 15+ design patterns automatically:

| Pattern | Detected When |
|---------|--------------|
| memory-storage | Using Memory MCP create/add operations |
| agent-selection | Invoking Task tool (subagents) |
| codebase-exploration | Using Explore subagent |
| implementation-planning | Using Plan subagent |
| capability-layering | Executing Scripts/ or .claude/jobs/ |
| worktree-workflow | Git worktree operations |
| autonomous-execution | Running claude-scheduled |
| skill-invocation | Using Skill tool |
| parc-design-review | Using design-review skill |
| task-orchestration | Using orchestration commands |
| mcp-integration | Using MCP tools |
| git-mcp-usage | Using Git MCP |
| filesystem-mcp-usage | Using Filesystem MCP |
| cross-project-work | Cross-project-commit-tracker active |
| web-research | Using WebFetch/WebSearch |

**View detected patterns**: Check `.claude/logs/audit.jsonl` `patterns` field

---

## Hook Types

| Type | When | Use For |
|------|------|---------|
| `SessionStart` | When Claude starts | Auto-load context, initialize state |
| `UserPromptSubmit` | User submits prompt | Correction detection, validation, enhancement |
| `PreToolUse` | Before tool runs | Validation, logging, blocking |
| `PostToolUse` | After tool completes | Verification, cleanup, notifications |
| `Notification` | Session events | Lifecycle tracking |
| `Stop` | When Claude ends | Notifications, cleanup |
| `SubagentStop` | Agent completes | Agent chaining, orchestration |
| `PreCompact` | Before compaction | Preserve critical state |

---

## Configuration

### Audit Verbosity
```bash
export CLAUDE_AUDIT_VERBOSITY=standard  # minimal | standard | full
```

### Health Monitor Critical Containers
```bash
export CRITICAL_CONTAINERS="caddy,n8n,loki,grafana,prometheus"
```

### Session Name
```bash
echo "My Session" > .claude/logs/.current-session
```

---

## Logs

- Audit log: `.claude/logs/audit.jsonl`
- Session activity: `.claude/logs/.session-activity`
- Entity metadata: `.claude/agents/memory/entity-metadata.json`
- Corrections: `.claude/logs/corrections.jsonl`
- Agent activity: `.claude/logs/agent-activity.jsonl`

---

## Creating New Hooks

Hooks use stdin/stdout format - read JSON context from stdin, output JSON result to stdout:

```javascript
#!/usr/bin/env node
async function handleHook(context) {
  const { tool, parameters } = context;
  // Your logic here
  return { proceed: true }; // or { proceed: false, message: "reason" }
}

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');
  const context = JSON.parse(input);
  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[my-hook] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
```

Register in `.claude/settings.json` under the appropriate event with a matcher.

---

## New in v2.1 (2026-02-05)

**6 new hooks synced from AIProjects:**
- `skill-router.js` - Routes slash commands to parent skills for workflow context
- `planning-mode-detector.js` - Detects planning-type requests, suggests `/plan` workflow
- `priority-validator.js` - Tracks work evidence (commits, files, services) for priority validation
- `compose-validator.js` - Validates docker-compose syntax and security before `docker compose up`
- `context-usage-tracker.js` - Estimates token usage per session, saves daily reports
- `index-sync.js` - Alerts when new files aren't referenced in `_index.md`

**Settings format updated** to command-based hook registration (matches current Claude Code format).

---

*AIfred Hooks v2.1 - Sync from AIProjects (2026-02-05)*

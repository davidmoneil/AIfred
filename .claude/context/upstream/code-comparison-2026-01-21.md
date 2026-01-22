# AIfred-Jarvis Side-by-Side Code Comparison

**Generated**: 2026-01-21
**Purpose**: Detailed mechanistic comparison of overlapping components
**Status**: SUPERSEDED by `integration-roadmap-2026-01-21.md`

---

## Corrections Notice

This document has been superseded by the comprehensive integration roadmap.
See: `.claude/context/upstream/integration-roadmap-2026-01-21.md`

**Key corrections addressed in roadmap**:
1. Session context comparison should include `session-start.sh` (Jarvis shell script) vs `session-start.js` (AIfred JS hook) — different architectures
2. `context-accumulator.js` EXISTS and is sophisticated (517 lines) — comparison with `pre-compact.js` is valid
3. Integration of `pre-compact.js` static files into JICM as preservation baseline
4. Jarvis credential-guard exceptions for own config files

---

## 1. Orchestration Detection Comparison

### Component Overview

| Aspect           | AIfred                        | Jarvis                        |
| ---------------- | ----------------------------- | ----------------------------- |
| **File**   | `orchestration-detector.js` | `orchestration-detector.js` |
| **Event**  | UserPromptSubmit              | UserPromptSubmit              |
| **Lines**  | ~350                          | ~633                          |
| **Format** | stdin/stdout                  | stdin/stdout (hybrid)         |

### Scoring System Comparison

**Identical Elements**:

- Build verbs scoring (+2 each, max 4)
- Scope words scoring (+2 each, max 4)
- Multi-component detection (+1 each, max 4)
- Explicit complexity markers (+3 each, max 6)
- Simplicity indicators penalty (-2 each)
- Skip patterns for simple commands
- Thresholds: SUGGEST=4, AUTO=9

**Jarvis Additions**:

```javascript
// AC-03 Milestone Review Detection
const CODE_WORK_PATTERNS = [
  /\b(build|implement|develop|code|write)\s+(a|an|the)?\s*(app|application|feature|system|api)/i,
  /\b(with|including|add)\s+(testing|tests|unit\s*tests|e2e|integration)/i,
  ...
];

const MULTI_PHASE_PATTERNS = [...];
const QUALITY_GATE_PATTERNS = [...];

function detectMilestoneReviewNeed(prompt) {
  // Returns: shouldUseMilestoneReview, codeWorkDetected, multiPhaseDetected, qualityGateDetected
}
```

```javascript
// MCP Tier Detection
const TIER3_MCP_PATTERNS = [/\b(browser|playwright|selenium|puppeteer)\b/i, ...];
const RESEARCH_MCP_PATTERNS = [/\b(research|investigate|deep\s*dive)\b/i, ...];

function detectMcpTiers(prompt) {
  // Returns: { tier3: [], research: [] }
}
```

```javascript
// Skill Routing
const SKILL_PATTERNS = {
  docx: [...],
  xlsx: [...],
  pdf: [...],
  pptx: [...],
  'mcp-builder': [...],
  'skill-creator': [...]
};

function detectSkills(prompt) {
  // Returns array of suggested skills
}
```

### Output Comparison

**AIfred Output**:

```javascript
{
  proceed: true,
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    orchestrationDetected: true,
    complexityScore: 12,
    action: 'auto-invoke',
    additionalContext: '... orchestration suggestion ...'
  }
}
```

**Jarvis Output** (superset):

```javascript
{
  proceed: true,
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    orchestrationDetected: true,
    complexityScore: 14,
    action: 'auto-invoke',
    suggestedSkills: ['xlsx', 'mcp-builder'],  // NEW
    mcpTiers: { tier3: [], research: ['deep-research'] },  // NEW
    milestoneReviewRecommended: true,  // NEW
    additionalContext: '... enhanced suggestion with milestone review ...'
  }
}
```

### Recommendation

**Keep Jarvis version** — it is a strict superset with:

- AC-03 milestone review integration
- Skill routing suggestions
- MCP tier detection
- All AIfred scoring logic preserved

---

## 2. Session Context Injection Comparison

### Component Overview

| Aspect            | AIfred                        | Jarvis                             |
| ----------------- | ----------------------------- | ---------------------------------- |
| **File**    | `session-start.js`          | `context-injector.js`            |
| **Event**   | SessionStart                  | PreToolUse                         |
| **Purpose** | Load context at session start | Inject hints before tool execution |
| **Timing**  | Once at start                 | Every tool call                    |

### Key Difference: Different Purposes

**AIfred session-start.js**:

```javascript
// Event: SessionStart - runs once when Claude Code starts
async function handler(context) {
  // Read session-state.md, current-priorities.md
  // Get git branch and uncommitted changes count
  // Inject as additionalContext for session awareness

  return {
    proceed: true,
    additionalContext: `
      Session State: ${sessionState}
      Git Branch: ${gitBranch}
      Uncommitted: ${uncommittedCount} files
    `
  };
}
```

**Jarvis context-injector.js**:

```javascript
// Event: PreToolUse - runs before every tool execution
async function handler(context) {
  const { tool, tool_input } = context;

  // Check context budget
  const contextUsage = getContextUsage();

  // Build tool-specific hints
  if (contextUsage >= 85) {
    injections.push('CRITICAL: 85% context used');
  }

  if (tool === 'Bash' && command.includes('cat ')) {
    injections.push('Use Read tool instead of cat');
  }

  return { proceed: true, additionalContext: injections.join('\n') };
}
```

### Complementary, Not Overlapping

These serve different purposes:

- **AIfred**: Session-level context loading
- **Jarvis**: Tool-level guidance

### Recommendation

**Both could coexist**:

1. Port AIfred's `session-start.js` for session context
2. Keep Jarvis's `context-injector.js` for tool guidance
3. Jarvis already has AC-01 startup protocol that subsumes session-start functionality

---

## 3. Audit Logging Comparison

### Component Overview

| Aspect           | AIfred                       | Jarvis                                    |
| ---------------- | ---------------------------- | ----------------------------------------- |
| **File**   | `audit-logger.js`          | `telemetry-emitter.js`                  |
| **Event**  | PreToolUse                   | CLI tool (not hook)                       |
| **Output** | `.claude/logs/audit.jsonl` | `.claude/logs/telemetry/events-*.jsonl` |

### Architecture Difference

**AIfred audit-logger.js** (Hook):

```javascript
// Runs as PreToolUse hook
module.exports = {
  name: 'audit-logger',
  event: 'PreToolUse',
  handler: async (context) => {
    const entry = {
      timestamp: new Date().toISOString(),
      session: getCurrentSession(),
      who: 'claude',
      type: 'tool_execution',
      tool: context.tool_name,
      parameters: context.tool_input,
      complexity: estimateComplexity(context),
      pattern: detectPattern(context)
    };

    await appendFile('audit.jsonl', JSON.stringify(entry) + '\n');
    return { proceed: true };
  }
};
```

**Jarvis telemetry-emitter.js** (Library):

```javascript
// Used as a module by other components
function emit(component, eventType, data = {}, metadata = {}) {
  const event = {
    timestamp: new Date().toISOString(),
    component,  // 'AC-01', 'AC-02', etc.
    event_type: eventType,
    session_id: getSessionId(),
    data,
    metadata: { jarvis_version: getJarvisVersion() }
  };

  writeToLog(event);
  return { success: true, event };
}

// Lifecycle helpers
const lifecycle = {
  start: (component, data) => emit(component, 'component_start', data),
  end: (component, data) => emit(component, 'component_end', data),
  error: (component, error, data) => emit(component, 'component_error', {...})
};

// Metric helpers
const metrics = {
  gauge: (component, name, value) => emit(component, 'metric', {...}),
  counter: (component, name, increment) => emit(component, 'metric', {...}),
  timing: (component, name, durationMs) => emit(component, 'metric', {...})
};
```

### Key Differences

| Feature | AIfred audit-logger    | Jarvis telemetry-emitter      |
| ------- | ---------------------- | ----------------------------- |
| Trigger | Every tool call (hook) | Explicit emit() calls         |
| Focus   | Tool execution audit   | Component lifecycle telemetry |
| Format  | Simple JSONL           | Structured with component IDs |
| Scope   | All tools              | Autonomic components (AC-*)   |
| Metrics | No                     | Yes (gauge, counter, timing)  |

### Recommendation

**Run both** — they serve different purposes:

1. AIfred audit-logger: Universal tool execution audit trail
2. Jarvis telemetry-emitter: Component-level observability

**Integration opportunity**: Have audit-logger emit to telemetry-emitter for unified logging.

---

## 4. Pre-Compact Preservation Comparison

### Component Overview

| Aspect             | AIfred             | Jarvis                                                     |
| ------------------ | ------------------ | ---------------------------------------------------------- |
| **File**     | `pre-compact.js` | `context-accumulator.js` → `context-compressor` agent |
| **Event**    | PreCompact         | PostToolUse (accumulator)                                  |
| **Approach** | Static file list   | Dynamic tracking + AI compression                          |

### Architecture Difference

**AIfred pre-compact.js** (Static):

```javascript
// Event: PreCompact - runs before conversation compaction
async function handler() {
  // Read static essential files
  const essentials = await readFile('compaction-essentials.md');
  const sessionState = await readFile('session-state.md');
  const blockers = await readFile('recent-blockers.md');

  return {
    proceed: true,
    preservedContext: `
      === ESSENTIAL CONTEXT ===
      ${essentials}

      === SESSION STATE ===
      ${sessionState}

      === BLOCKERS ===
      ${blockers}
    `
  };
}
```

**Jarvis JICM System** (Dynamic):

```javascript
// context-accumulator.js (PostToolUse) - tracks during session
function trackContextUsage(tool, parameters) {
  // Records files read, tools used, context accumulated
  // Writes to context-estimate.json
}

// context-compressor agent - AI-powered compression
// Triggered by jarvis-watcher.sh when context > 80%
// Uses Opus model to intelligently compress:
// - Retain skeleton + current step for multi-step workflows
// - Summarize resolved issues with learnings
// - Preserve active work, drop completed context
```

### Comparison

| Feature            | AIfred pre-compact | Jarvis JICM           |
| ------------------ | ------------------ | --------------------- |
| Trigger            | PreCompact event   | 80% context threshold |
| Content            | Static file list   | Dynamic analysis      |
| Intelligence       | None (file copy)   | AI compression        |
| Customization      | Edit file list     | Agent prompt          |
| Session continuity | Basic              | Learnings preserved   |

### Recommendation

**Keep Jarvis JICM** — it's more sophisticated. However:

- Consider AIfred's `compaction-essentials.md` as baseline for JICM
- The static list could inform what JICM should always preserve

---

## 5. Secret Scanning Comparison

### Component Overview

| Aspect           | AIfred                | Jarvis                |
| ---------------- | --------------------- | --------------------- |
| **File**   | `secret-scanner.js` | `secret-scanner.js` |
| **Event**  | PreToolUse            | PreToolUse            |
| **Status** | **Identical**   | **Identical**   |

### Code Comparison

Both files are functionally identical:

```javascript
// Pattern detection for secrets
const SECRET_PATTERNS = [
  { name: 'AWS Access Key', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'GitHub Token', pattern: /gh[ps]_[a-zA-Z0-9]{36}/ },
  { name: 'Generic API Key', pattern: /api[_-]?key["']?\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/i },
  { name: 'Private Key', pattern: /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: 'JWT Token', pattern: /eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/ }
];

// Filter false positives
const FALSE_POSITIVE_PATTERNS = [
  /example|test|sample|dummy|placeholder/i,
  /\.example$|\.sample$|\.template$/
];
```

### Recommendation

**No action needed** — already identical in both codebases.

---

## 6. Security Hooks (AIfred-Only) Analysis

### credential-guard.js

```javascript
// BLOCKED_PATHS - Never read these
const BLOCKED_PATHS = [
  /\.ssh\/id_/,                    // SSH keys
  /\.ssh\/.*_key$/,
  /\.aws\/credentials$/,           // AWS credentials
  /\.aws\/config$/,
  /\.npmrc$/,                      // NPM auth
  /\.netrc$/,
  /\.docker\/config\.json$/,       // Docker auth
  /\.anthropic/,                   // Anthropic API
  /\.openai/,                      // OpenAI API
  /\.env$/,                        // Environment files
  /\.env\.[^/]+$/,
  /secrets\.ya?ml$/,
  /credentials\.json$/,
  /service-account.*\.json$/
];

// Handler blocks Read/Write/Bash access to these paths
if (isBlockedPath(filePath)) {
  return {
    proceed: false,
    message: `Blocked: Cannot read credential file ${path.basename(filePath)}`
  };
}
```

### branch-protection.js

```javascript
// Protected branches
const PROTECTED_BRANCHES = ['main', 'master', 'production', 'prod', 'release', 'stable'];

// Dangerous patterns
const DANGEROUS_PATTERNS = [
  { pattern: /git\s+push\s+.*--force/, action: 'force push', severity: 'high' },
  { pattern: /git\s+push\s+-f\s/, action: 'force push', severity: 'high' },
  { pattern: /git\s+reset\s+--hard/, action: 'hard reset', severity: 'medium' },
  { pattern: /git\s+branch\s+-[dD]\s+(main|master|production)/, action: 'delete protected branch', severity: 'high' }
];

// Handler blocks high-severity operations on protected branches
if (affectsProtected && severity === 'high') {
  return {
    proceed: false,
    message: `Blocked: ${action} on protected branch ${targetBranch}`
  };
}
```

### Jarvis Gap Analysis

Jarvis has:

- `dangerous-op-guard.js` — Blocks some destructive operations
- `workspace-guard.js` — Protects workspace boundaries

Jarvis lacks:

- Credential file access blocking (credential-guard)
- Branch protection for force push (branch-protection)

### Recommendation

**Port both hooks** — they fill security gaps:

1. `credential-guard.js` — Critical for preventing credential exposure
2. `branch-protection.js` — Important for git safety

---

## 7. Observability Hooks (AIfred-Only) Analysis

### health-monitor.js

```javascript
// Monitors Docker container health continuously
const CRITICAL_CONTAINERS = ['postgres', 'redis', 'nginx'];

async function checkContainerHealth() {
  const result = await execAsync('docker ps --format "{{.Names}}|{{.Status}}"');

  for (const line of result.stdout.split('\n')) {
    const [name, status] = line.split('|');

    // Check for state changes
    if (previousState !== currentState) {
      console.log(`[health-monitor] Container ${name} changed: ${previousState} -> ${currentState}`);

      if (CRITICAL_CONTAINERS.includes(name) && currentState === 'unhealthy') {
        // Alert on critical container degradation
      }
    }
  }
}
```

### file-access-tracker.js

```javascript
// Tracks file read patterns for analytics
const TRACKED_PATHS = [
  '.claude/context/',
  '.claude/commands/',
  'knowledge/'
];

async function handler(context) {
  if (context.tool === 'Read') {
    const filePath = context.tool_input?.file_path;

    if (isTrackedPath(filePath)) {
      // Update access statistics
      stats[filePath] = {
        readCount: (stats[filePath]?.readCount || 0) + 1,
        lastAccessed: new Date().toISOString(),
        sessions: [...(stats[filePath]?.sessions || []), sessionId]
      };

      await writeFile('file-access.json', JSON.stringify(stats));
    }
  }
}
```

### Recommendation

**Port both hooks** — they enhance observability:

1. `health-monitor.js` — Continuous Docker monitoring
2. `file-access-tracker.js` — Usage analytics for context optimization

---

## Summary: Code-Level Recommendations

### Keep Jarvis Version (Superset)

1. `orchestration-detector.js` — Jarvis version has AC-03, skill routing, MCP tiers

### Keep Both (Complementary)

2. Session context injection — Different purposes (session vs tool level)
3. Audit logging — Different scopes (tools vs components)

### Keep Jarvis (More Sophisticated)

4. Context preservation — JICM is more intelligent than static file list

### No Action (Identical)

5. `secret-scanner.js` — Already the same

### Port from AIfred (Gap Fill)

6. `credential-guard.js` — Critical security gap
7. `branch-protection.js` — Git safety gap
8. `health-monitor.js` — Observability enhancement
9. `file-access-tracker.js` — Analytics capability

---

*Code comparison generated for /sync-aifred-baseline comprehensive analysis — Jarvis v2.0.0*

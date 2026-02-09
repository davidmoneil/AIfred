# /tooling-health Command

Validate Claude Code tooling status and generate a comprehensive health report.

## Usage

```
/tooling-health
/tooling-health --quick    # Skip MCP tool inventory
/tooling-health --verbose  # Include all appendices
```

---

## CRITICAL: Report Generation Workflow

**This command produces a STANDARDIZED report.** Follow these steps exactly:

### Phase 1: Data Collection (MANDATORY)

Execute ALL these checks before writing the report:

```bash
# 1. MCP Servers
claude mcp list

# 2. Plugins
cat ~/.claude/plugins/installed_plugins.json

# 3. Hook Validation
for f in .claude/hooks/*.js; do node -c "$f" 2>/dev/null && echo "✓ $(basename $f)" || echo "✗ $(basename $f)"; done

# 4. Hook Structure Check (run the full validation script in Implementation section)
```

### Phase 2: MCP Tool Testing (MANDATORY)

For EACH connected MCP, test at least one tool:

| MCP | Required Test |
|-----|---------------|
| memory | `mcp__memory__read_graph` |
| filesystem | `mcp__filesystem__list_allowed_directories` |
| fetch | Note availability |
| time | `mcp__time__get_current_time` |
| git | `mcp__git__git_status` |
| sequential-thinking | Note availability |
| github | Test or document failure |

### Phase 3: Report Generation (MANDATORY TEMPLATE)

**IMPORTANT**: The report MUST include ALL sections from the template below. Missing sections indicate an incomplete report.

---

## Mandatory Report Template

```markdown
# Tooling Health Report

**Generated**: YYYY-MM-DD HH:MM TZ
**Revised**: (if applicable)
**Claude Code Version**: Model name (model ID)
**Workspace**: `/path/to/workspace`
**Branch**: `branch-name`

---

## Executive Summary

| Category | Status | Details |
|----------|--------|---------|
| **Context Budget** | STATUS | X/200K tokens (Y%) |
| MCP Servers | STATUS | X/7 Stage 1 connected |
| Plugins | STATUS | X installed, X PR-5 targets |
| Skills | STATUS | Brief note |
| Built-in Tools | STATUS | All/partial available |
| Hooks | STATUS | X/Y validated |
| Subagents | STATUS | X available |
| Custom Agents | STATUS | (if applicable) |
| Commands | STATUS | X project + X built-in |

**Overall Health**: STATUS - Summary statement

---

## Detailed Findings

### 1. MCP Servers

#### Stage 1 Baseline Status

| Server | Status | Token Cost | Tools | Notes |
|--------|--------|------------|-------|-------|
| memory | STATUS | ~8-15K | 8 | Test result |
| filesystem | STATUS | ~8K | 13 | Test result |
| fetch | STATUS | ~5K | 1 | Test result |
| time | STATUS | ~3K | 2 | Test result |
| git | STATUS | ~6K | 13 | Test result |
| sequential-thinking | STATUS | ~5K | 1 | Test result |
| github | STATUS | ~15K | ~20+ | Test result |

**Stage 1 Coverage**: X/7 (XX%)

#### MCP Tool Inventory

**Memory MCP (8 tools)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `create_entities` | ✓/✗ | GO/WARN/FAIL | |
| `create_relations` | ✓/✗ | GO/WARN/FAIL | |
| `add_observations` | ✓/✗ | GO/WARN/FAIL | |
| `delete_entities` | ✓/✗ | GO/WARN/FAIL | |
| `delete_observations` | ✓/✗ | GO/WARN/FAIL | |
| `delete_relations` | ✓/✗ | GO/WARN/FAIL | |
| `read_graph` | ✓/✗ | GO/WARN/FAIL | |
| `search_nodes` | ✓/✗ | GO/WARN/FAIL | |
| `open_nodes` | ✓/✗ | GO/WARN/FAIL | |

(Repeat for each connected MCP...)

---

### 2. Plugins

#### Current Installation Status

| Plugin | Scope | Version | Source | PR-5 Priority |
|--------|-------|---------|--------|---------------|
| name | user/project | version | source | HIGH/MED/LOW/Extra |

#### PR-5 Target Coverage

| Priority | Target | Installed | Status |
|----------|--------|-----------|--------|
| HIGH | X | Y | STATUS |
| MEDIUM | X | Y | STATUS |
| LOW | X | Y | STATUS |
| **Total** | **X** | **Y** | **XX%** |

---

### 3. Hooks

#### Validation Summary

| Test | Passed | Failed | Details |
|------|--------|--------|---------|
| Syntax Check | X/Y | Z | Notes |
| Module Load | X/Y | Z | Notes |
| Format Check | X/Y | Z | X module, Y CLI, Z bare |
| **Total** | **X** | **Y** | |

#### By Category

(Include tables for each category: Lifecycle, Guardrail, Security, Observability, Documentation, Utility)

#### Failed Hooks (if any)

```
Hook: filename.js
Error: error message
Resolution: suggested fix
```

---

### 4. Skills

| Skill | Location | Purpose | Status |
|-------|----------|---------|--------|
| name | path | description | STATUS |

---

### 5. Subagents

| Subagent | Status | Purpose |
|----------|--------|---------|
| Explore | STATUS | Codebase exploration |
| Plan | STATUS | Implementation planning |
| claude-code-guide | STATUS | Documentation lookup |
| general-purpose | STATUS | Complex tasks |
| statusline-setup | STATUS | Status line config |

---

### 6. Custom Agents (if applicable)

| Agent | File | Purpose | Recognition Status |
|-------|------|---------|-------------------|
| name | path | purpose | Recognized/Not recognized |

---

### 7. Commands

#### Project Commands
| Command | Purpose | Stoppage Hook |
|---------|---------|---------------|
| /command | description | Yes/No |

---

## Issues Requiring Attention

### Issue #1: [Title]

**Severity**: `[X] CRITICAL` / `[!] HIGH` / `[~] MEDIUM` / `[-] LOW`

#### Assessment
(What's wrong, what's the impact)

#### Root Cause Analysis
(Why is this happening)

#### Recommended Plan
(Step-by-step fix with commands)

(Repeat for each issue...)

---

## Stage 1 Baseline Summary

### Current State

```
MCP Servers:     X/7  (XX%)  - Notes
MCP Tools:       X/Y  (XX%)  - Notes
Plugins:         X/Y  (XX%)  - Notes
Skills:          X/Y  (XX%)  - Notes
Hooks:           X/Y  (XX%)  - Notes
Built-in Tools:  X/Y  (XX%)
Subagents:       X/Y  (XX%)
```

### Target State (PR-5)

```
MCP Servers:     7/7   (100%)
MCP Tools:       38/38 (100%)
Plugins:         X/X   (100%)
etc.
```

---

## Action Items Summary

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| `[!] HIGH` | action | Xm | impact |
| `[~] MEDIUM` | action | Xm | impact |
| `[-] LOW` | action | Xm | impact |

---

## Appendices

### Appendix A: MCP Server Configuration
(Raw `claude mcp list` output)

### Appendix B: Plugin Installation JSON
(Raw JSON from installed_plugins.json)

### Appendix C: Hook Validation Output
(Full validation script output)

---

## Related Documentation

- Links to relevant context files

---

*Report generated by `/tooling-health` command*
*PR-5 Core Tooling Baseline*
```

---

## Validation Checklist

Before finalizing the report, verify:

- [ ] Executive Summary includes ALL categories
- [ ] MCP Tool Inventory lists tools for each connected MCP
- [ ] Plugin table includes PR-5 priority classification
- [ ] Hook validation includes all 3 tests (syntax, load, structure)
- [ ] Issues section includes root cause analysis AND recommended plan
- [ ] Stage 1 Baseline Summary has both current and target states
- [ ] Action Items have effort estimates
- [ ] At least one appendix with raw data

---

## Implementation Details

### 1. Check MCP Servers

```bash
claude mcp list
```

Then test each connected server with the appropriate MCP tool.

### 2. Check Plugins

```bash
cat ~/.claude/plugins/installed_plugins.json
```

Classify each plugin by:
- Source: claude-code-plugins, claude-plugins-official, third-party
- PR-5 Priority: HIGH, MEDIUM, LOW, Extra, N/A

### 3. Check Hooks

#### Syntax Validation

```bash
echo "=== SYNTAX CHECK ==="
for f in .claude/hooks/*.js; do
  if node -c "$f" 2>/dev/null; then
    echo "✓ $(basename $f)"
  else
    echo "✗ $(basename $f) - SYNTAX ERROR"
  fi
done
```

#### Structure Validation

```bash
echo "=== FORMAT & STRUCTURE CHECK ==="
node -e "
const fs = require('fs');
const path = require('path');

const HOOKS_DIR = '.claude/hooks';
const CLI_HOOKS = ['permission-gate.js', 'project-detector.js'];

const results = {
  load: { passed: 0, failed: 0 },
  format: { module: 0, cli: 0, bare: 0, invalid: 0 }
};

const hookFiles = fs.readdirSync(HOOKS_DIR).filter(f => f.endsWith('.js'));
console.log('Found ' + hookFiles.length + ' hooks\n');

for (const file of hookFiles) {
  const hookPath = path.join(process.cwd(), HOOKS_DIR, file);

  if (CLI_HOOKS.includes(file)) {
    results.load.passed++;
    results.format.cli++;
    console.log('✓ ' + file + ' (CLI-style)');
    continue;
  }

  let hook;
  try {
    hook = require(hookPath);
    results.load.passed++;
  } catch (e) {
    results.load.failed++;
    console.log('✗ ' + file + ' - LOAD FAILED: ' + e.message);
    continue;
  }

  if (typeof hook === 'function') {
    results.format.bare++;
    console.log('✓ ' + file + ' (bare function)');
  } else if (hook.handler && hook.name && hook.event) {
    results.format.module++;
    console.log('✓ ' + file + ' (' + hook.event + ')');
  } else if (hook.handler || typeof hook === 'object') {
    results.format.module++;
    console.log('✓ ' + file + ' (' + (hook.event || 'unknown') + ')');
  } else {
    results.format.invalid++;
    console.log('? ' + file + ' - unrecognized format');
  }
}

console.log('\n=== SUMMARY ===');
console.log('Load: ' + results.load.passed + '/' + hookFiles.length);
console.log('Module: ' + results.format.module + ' | CLI: ' + results.format.cli + ' | Bare: ' + results.format.bare);
console.log(results.load.failed === 0 && results.format.invalid === 0 ? '✅ All hooks valid' : '⚠️ Issues found');
"
```

### 4. Check Subagents

Verify Task tool can spawn: Explore, Plan, claude-code-guide, general-purpose, statusline-setup

### 5. Generate Report

1. Save to `.claude/reports/tooling-health-YYYY-MM-DD.md`
2. If revising same-day report, use `-vN` suffix (e.g., `-v2`)
3. Update session-state.md with report reference

---

## Reference Reports

For format guidance, see:
- `.claude/reports/tooling-health-2026-01-06.md` (comprehensive example)

---

## Related Documentation

- @.claude/context/integrations/capability-map.yaml - Task to tool selection
- @.claude/context/integrations/mcp-installation.md - MCP installation procedures
- @.claude/context/integrations/overlap-analysis.md - Tool overlap resolution
- @.claude/hooks/README.md - Hooks documentation
- @.claude/commands/health-report.md - Infrastructure health

---

*PR-5 Core Tooling Baseline - Tooling Health Check v2.0*
*Updated: 2026-01-06 - Added mandatory template, validation checklist, hooks validation*

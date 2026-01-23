# Setup UX Improvements

*Created: 2026-01-06*
*Source: Option C Thorough Validation (v1.3.0)*
*Status: Brainstorm*

---

## Overview

During thorough validation of the v1.3.0 setup process, several UX and architectural issues were identified that should be addressed in future PRs.

---

## Issues by Phase

### Phase 2: Purpose Interview

**Issue**: Projects root default detection is suboptimal

**Current Behavior**: Auto-detects `/Users/aircannon/Claude` with existing repos

**Expected Behavior**: Default should be `/Users/aircannon/Claude/Projects` - a dedicated subdirectory for code projects separate from Jarvis and other tools.

**Rationale**: Code projects (and any project beyond Project Aion self-evolution) should keep their codebases, knowledge bases, and planning docs within their own subfolder of a dedicated Projects directory.

**Default Answers Should Be**:
```
What will you primarily use Jarvis for?     → All of the above
How much automation do you want?            → Full Automation
Enable Memory MCP?                          → Yes, enable memory
Where should code projects live?            → /Users/aircannon/Claude/Projects
```

**Fix**: Update Phase 2 to use `$HOME/Claude/Projects` as default, create if not exists.

---

### Phase 3: MCP Configuration

**Issue**: Docker Desktop MCP requirement is confusing and unnecessary

**Current Behavior**: Setup expects Docker Desktop MCP to be enabled and tries to deploy mcp-gateway container which fails because it's designed as a stdio server, not a daemon.

**Problems**:
1. Container keeps restarting (exit code 0) because it's stdio-based
2. User is told to enable Docker Desktop MCP in Settings → Features → Beta
3. Unclear why Docker Desktop is required vs just Docker CLI

**Expected Behavior**:
1. Detect Docker CLI tools on local system (not Docker Desktop specifically)
2. Run a tmp container to validate Docker functionality
3. Only deploy mcp-gateway if actually needed
4. Make Docker Desktop MCP an optional enhancement, not a requirement

**Questions to Answer**:
- What exactly does mcp-gateway do?
- Is Docker Desktop MCP essential for MCP servers to launch containers?
- Can this all be done with hooks, scripts, or CLI instead?

**Fix**: Refactor Phase 3 to:
1. Detect Docker CLI: `docker --version && docker info`
2. Validate with tmp container: `docker run --rm hello-world`
3. Make mcp-gateway optional, explain what it provides
4. Remove Docker Desktop MCP as hard requirement

---

### Phase 5: Hooks & Automation

**Issue**: Hook syntax validation output is confusing

**Current Behavior**: First loop shows all "❌ Syntax error" then second loop shows all "✅ Valid"

**Example Output**:
```
: ❌ Syntax error
: ❌ Syntax error
: ❌ Syntax error
...
audit-logger.js: ✅
context-reminder.js: ✅
...
```

**Root Cause**: First validation loop's grep logic fails, showing errors for valid hooks. The actual `node -c` check succeeds.

**Fix**:
1. Fix the grep/validation logic in hook syntax check
2. Suppress intermediate error output
3. Only show final pass/fail status per hook

---

### Phase 6: Agent Deployment

**Issue**: No user agency in agent selection

**Current Behavior**: All 3 agents auto-deployed without user input

**Expected Behavior**:
1. Present core agents with descriptions
2. Allow user to confirm which to install
3. Show optional/additional agents available for later
4. Provide `/install-agent <name>` for deferred installation

**Fix**: Add interview step for agent selection with default "install all core agents".

---

### Phase 7: Finalization

**Issue**: Verbose bash script shown to user before execution

**Current Behavior**: The entire readiness report bash script (100+ lines) is displayed in the terminal awaiting approval, then the actual output is hidden behind ctrl+o.

**Problems**:
1. User sees raw variable declarations, if statements, echo commands
2. Actual report output is collapsed/hidden
3. Poor UX - user wants results, not implementation

**Example of What User Sees**:
```bash
JARVIS_PATH="/tmp/jarvis-validation-test/Jarvis"
AIFRED_PATH="/Users/aircannon/Claude/AIfred"
CRITICAL_PASS=0
...hundreds of lines of bash...
```

**Expected Behavior**:
1. User approves running a script (one line)
2. Script runs
3. User sees the report output prominently

**Fix**:
1. Move readiness report logic to `scripts/setup-readiness.sh`
2. Command just runs: `./scripts/setup-readiness.sh`
3. User approves one-line command, sees clean output

---

## Recommendations

### Immediate (PR-5 scope)
- [ ] Fix hook validation output logic
- [ ] Move readiness report to external script

### Near-term (PR-6-7 scope)
- [ ] Refactor Phase 3 Docker/MCP handling
- [ ] Add agent selection interview
- [ ] Update projects_root default

### Design Decisions Needed
- [ ] What is mcp-gateway's actual purpose?
- [ ] Is Docker Desktop MCP truly required?
- [ ] Should we support non-Docker MCP alternatives?

---

## Validation Result

Despite UX issues, the setup completed successfully:

```
STATUS: ✅ FULLY READY
Total: 17/17 checks passed

Phase Summary:
| Phase                | Status                                        |
|----------------------|-----------------------------------------------|
| 0A Preflight         | ✅ Passed (12/12 checks)                      |
| 0B Prerequisites     | ✅ Passed (Git, Docker, Node.js)              |
| 1 System Discovery   | ✅ Complete                                   |
| 2 Purpose Interview  | ✅ Full Automation, All focus areas           |
| 3 Foundation Setup   | ✅ paths-registry.yaml created                |
| 4 MCP Integration    | ✅ Configured (pending Docker MCP enablement) |
| 5 Hooks & Automation | ✅ 11 hooks validated                         |
| 6 Agent Deployment   | ✅ 3 agents deployed                          |
| 7 Finalization       | ✅ FULLY READY                                |
```

---

*Setup UX Improvements — Captured from v1.3.0 validation*

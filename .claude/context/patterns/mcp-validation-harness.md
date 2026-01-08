# MCP Validation Harness Pattern

**Created**: 2026-01-08
**Status**: Draft
**Related**: PR-8.4, capability-matrix.md, mcp-installation.md

---

## Purpose

Systematic validation of newly installed MCPs to ensure:
1. Tools are functional and properly configured
2. Usage patterns are documented for effective task selection
3. Token costs are measured and budgeted
4. Tier placement (1/2/3) is determined based on evidence
5. Overlap with existing tools is identified and resolved

---

## The Problem

Installing non-functional or poorly-understood MCPs causes:
- **Wasted context space** on tools that don't work
- **Failed task execution** when non-functional tools are selected
- **Workaround overhead** when agents must redesign around failures
- **Token waste** from retry loops and error handling
- **Roadmap drift** from unplanned troubleshooting

---

## Validation Phases

### Phase 1: Installation Verification

```
┌─────────────────────────────────────────────────────────┐
│  INSTALLATION VERIFICATION                              │
├─────────────────────────────────────────────────────────┤
│  1. Server Registration                                 │
│     □ MCP appears in `claude mcp list`                  │
│     □ Configuration in correct location                 │
│       - Global: ~/.claude.json                          │
│       - Project: .mcp.json                              │
│                                                         │
│  2. Server Startup                                      │
│     □ No startup errors in logs                         │
│     □ Server responds to health check (if supported)    │
│                                                         │
│  3. Tool Discovery                                      │
│     □ Tools appear in Claude's available tools          │
│     □ Tool count matches expected                       │
│     □ No duplicate tool names with existing MCPs        │
└─────────────────────────────────────────────────────────┘
```

**Validation Script**: `.claude/scripts/validate-mcp-installation.sh`

### Phase 2: Configuration Audit

```
┌─────────────────────────────────────────────────────────┐
│  CONFIGURATION AUDIT                                    │
├─────────────────────────────────────────────────────────┤
│  1. Required Configuration                              │
│     □ API keys present and valid format                 │
│     □ Paths exist and are accessible                    │
│     □ Permissions are correct                           │
│                                                         │
│  2. Optional Configuration                              │
│     □ Defaults documented                               │
│     □ Override mechanisms understood                    │
│                                                         │
│  3. Environment Dependencies                            │
│     □ Required env vars set                             │
│     □ External services reachable                       │
│     □ Network requirements documented                   │
└─────────────────────────────────────────────────────────┘
```

**Output**: Configuration requirements documented in mcp-installation.md

### Phase 3: Tool Inventory

```
┌─────────────────────────────────────────────────────────┐
│  TOOL INVENTORY                                         │
├─────────────────────────────────────────────────────────┤
│  For each tool in the MCP:                              │
│                                                         │
│  1. Tool Metadata                                       │
│     □ Name and description                              │
│     □ Required parameters                               │
│     □ Optional parameters with defaults                 │
│     □ Return value format                               │
│                                                         │
│  2. Token Cost Estimate                                 │
│     □ Tool definition tokens                            │
│     □ Typical invocation tokens                         │
│     □ Typical response tokens                           │
│                                                         │
│  3. Overlap Analysis                                    │
│     □ Compare with existing tools in capability-matrix  │
│     □ Identify redundancy (same capability)             │
│     □ Identify complementarity (enhanced capability)    │
│     □ Document preferred tool for each use case         │
└─────────────────────────────────────────────────────────┘
```

**Output**: Tool inventory table for capability-matrix.md

### Phase 4: Functional Testing

```
┌─────────────────────────────────────────────────────────┐
│  FUNCTIONAL TESTING                                     │
├─────────────────────────────────────────────────────────┤
│  For each tool, execute:                                │
│                                                         │
│  1. Happy Path Test                                     │
│     □ Valid inputs → Expected output                    │
│     □ Document successful invocation pattern            │
│                                                         │
│  2. Error Handling Test                                 │
│     □ Invalid inputs → Graceful error                   │
│     □ Missing required params → Clear message           │
│     □ Service unavailable → Appropriate failure         │
│                                                         │
│  3. Edge Case Test (if applicable)                      │
│     □ Empty inputs                                      │
│     □ Large inputs                                      │
│     □ Special characters                                │
│                                                         │
│  4. Integration Test                                    │
│     □ Tool works in realistic workflow                  │
│     □ Output usable by subsequent operations            │
└─────────────────────────────────────────────────────────┘
```

**Output**: Test results log, usage examples for documentation

### Phase 5: Tier Recommendation

```
┌─────────────────────────────────────────────────────────┐
│  TIER RECOMMENDATION MATRIX                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  TIER 1 (Always-On) Criteria:                           │
│  □ Used in >50% of sessions                             │
│  □ Token cost <3K                                       │
│  □ Core to primary workflows                            │
│  □ No external dependencies that may fail               │
│  Examples: memory, filesystem, fetch                    │
│                                                         │
│  TIER 2 (Task-Scoped) Criteria:                         │
│  □ Used in specific task categories                     │
│  □ Token cost 3K-8K                                     │
│  □ Can be predicted at session start                    │
│  □ Benefits from persistent connection                  │
│  Examples: github, context7, sequential-thinking        │
│                                                         │
│  TIER 3 (Triggered/Isolated) Criteria:                  │
│  □ Infrequent use (<20% of sessions)                    │
│  □ Token cost >8K OR spawns isolated process            │
│  □ Task-specific activation                             │
│  □ Clean termination after use                          │
│  Examples: playwright, browserstack                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Output**: Tier recommendation with justification

---

## Validation Outputs

### 1. MCP Status Entry

Add to `mcp-installation.md`:

```markdown
### [MCP Name]

**Status**: Validated | Partial | Failed
**Tier**: 1 | 2 | 3
**Token Cost**: ~XK tokens
**Validated**: YYYY-MM-DD

**Tools**:
| Tool | Purpose | Status |
|------|---------|--------|
| tool_name | Brief description | ✅ Working |

**Configuration**:
- Required: API_KEY in env
- Optional: SETTING=default

**Usage Pattern**:
- Best for: [specific use cases]
- Avoid for: [anti-patterns]
- Prefer over: [redundant tools]

**Known Issues**:
- [Any discovered limitations]
```

### 2. Capability Matrix Update

Add to `capability-matrix.md`:

```markdown
| Capability | Primary Tool | MCP | Fallback |
|------------|--------------|-----|----------|
| [capability] | [tool_name] | [mcp_name] | [alternative] |
```

### 3. Test Results Log

Store at `.claude/logs/mcp-validation/[mcp-name].md`:

```markdown
# [MCP Name] Validation Results

**Date**: YYYY-MM-DD
**Version**: X.Y.Z
**Validator**: Claude/User

## Phase 1: Installation
- [x] Server registered
- [x] No startup errors
- [x] Tools discovered: N tools

## Phase 2: Configuration
- [x] API key validated
- [x] Paths accessible

## Phase 3: Tool Inventory
[Tool inventory table]

## Phase 4: Functional Tests
[Test results per tool]

## Phase 5: Tier Recommendation
**Recommended Tier**: X
**Justification**: [reasoning]
```

---

## Validation Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                  MCP VALIDATION WORKFLOW                      │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  1. INSTALL MCP                                              │
│     - Add to .mcp.json or ~/.claude.json                     │
│     - Set required configuration                             │
│     - Restart Claude session                                 │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  2. RUN INSTALLATION CHECK                                   │
│     - ./scripts/validate-mcp-installation.sh [mcp-name]      │
│     - Verify tools appear in context                         │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  3. INVOKE /validate-mcp [mcp-name]                          │
│     - Triggers validation harness skill                      │
│     - Runs through all 5 phases                              │
│     - Generates validation report                            │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  4. REVIEW RESULTS                                           │
│     - Check test results                                     │
│     - Review tier recommendation                             │
│     - Identify any blockers                                  │
└──────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐  ┌───────────────────┐
        │  VALIDATION PASS  │  │  VALIDATION FAIL  │
        │                   │  │                   │
        │  - Update docs    │  │  - Log issues     │
        │  - Set tier       │  │  - Disable MCP    │
        │  - Enable MCP     │  │  - Create ticket  │
        └───────────────────┘  └───────────────────┘
```

---

## Command: /validate-mcp

**Purpose**: Execute validation harness for a specific MCP

**Usage**:
```
/validate-mcp [mcp-name]
/validate-mcp git          # Validate Git MCP
/validate-mcp --all        # Validate all enabled MCPs
/validate-mcp --quick git  # Skip functional tests (Phase 4)
```

**Flags**:
- `--quick`: Skip Phase 4 functional tests
- `--all`: Run on all currently enabled MCPs
- `--report`: Generate detailed markdown report

---

## Integration Points

### With Context Budget Management
- Token costs feed into budget calculations
- Tier placement affects loading decisions
- Overlap analysis prevents redundant loading

### With Capability Matrix
- Validated tools added to matrix
- Redundancy identified and resolved
- Fallback chains updated

### With Session Management
- New MCPs require validation before production use
- Failed validation triggers disable recommendation
- Successful validation unlocks tier-appropriate loading

---

## Design MCPs (For Harness Development)

These MCPs are already installed and will be used to design/debug the harness:

| MCP | Tools | Why Selected |
|-----|-------|--------------|
| **Git** | 12 | Daily use, well-understood baseline |
| **Memory** | 9 | Testable CRUD, stateful operations |
| **Filesystem** | 13 | Comprehensive, permission testing |

## Testing MCPs (For Harness Validation)

These MCPs will be installed to test the harness works on fresh installs:

| MCP | Tools | Why Selected |
|-----|-------|--------------|
| **Brave Search** | 6 | API key config, external service |
| **arXiv** | 4 | Simpler setup, research utility |
| **DuckDuckGo** | ~2 | Minimal config, Stage 1 priority |

---

*MCP Validation Harness Pattern — PR-8.4*

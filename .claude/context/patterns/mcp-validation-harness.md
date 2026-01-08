# MCP Validation Harness Pattern

**Created**: 2026-01-08
**Updated**: 2026-01-08
**Status**: Active
**Related**: PR-8.4, capability-matrix.md, mcp-installation.md, batch-mcp-validation.md

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

## Batch Validation

When validating many MCPs, use the **Batch MCP Validation Pattern** to ensure all tools load:

**See**: `batch-mcp-validation.md`

**Quick Start**:
```bash
# Configure batch 1 (Development MCPs)
.claude/scripts/mcp-validation-batches.sh 1

# Apply changes
/clear

# Run functional tests for batch 1 MCPs

# Move to next batch
.claude/scripts/mcp-validation-batches.sh 2
```

**Batches**:
| Batch | MCPs | Focus |
|-------|------|-------|
| 1 | 8 | Development (github, context7, sequential-thinking, datetime) |
| 2 | 8 | Research (brave-search, arxiv, perplexity, wikipedia) |
| 3 | 7 | Utilities (desktop-commander, chroma, gptresearcher) |
| 4 | 6 | Specialized (playwright, lotus-wisdom) |

---

## Integration Points

### With Context Budget Management
- Token costs feed into budget calculations
- Tier placement affects loading decisions
- Overlap analysis prevents redundant loading
- **Batch validation ensures all tools load within token limits**

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

## Lessons Learned (From Validation Testing)

**Updated**: 2026-01-09

### Critical Discoveries

1. **Mid-Session Installation Limitation**
   - MCPs installed during a session show "Connected" in `claude mcp list`
   - Tools are NOT available until session restart
   - Phase 4 must be deferred to next session for new installs

2. **External Service Reliability**
   - MCP can be "working" but external service may block requests
   - DuckDuckGo triggers bot detection even on first request
   - Phase 4 testing must verify actual external service behavior

3. **Package Naming Inconsistency**
   - Documentation often references non-existent packages
   - Python (uvx) vs Node (npx) variants may have different names
   - Always verify package exists: `npx -y [package] --help` or `uvx [package] --help`

4. **API Key Gating**
   - MCPs requiring API keys should be flagged early in Phase 2
   - Missing prerequisites = defer validation, don't attempt Phase 3+
   - Document API key acquisition steps

5. **Multiple Implementations of Same MCP** (NEW - 2026-01-09)
   - Different npm/pypi packages may expose same MCP concept
   - Example: DuckDuckGo has at least 3 implementations:
     - `zhsama/duckduckgo-mcp-server` (npm, TypeScript, uses duck-duck-scrape)
     - `nickclyde/duckduckgo-mcp-server` (Python, uses duckduckgo-search)
     - Community forks with varying maintenance
   - **Always identify exact package/repo before troubleshooting**
   - Different implementations have different rate limiting, features, reliability

6. **Troubleshooting Bot Detection** (NEW - 2026-01-09)
   - If MCP returns "anomaly detected" or rate limit errors:
     1. Identify exact package implementation
     2. Check if Python vs Node version available
     3. Try longer delays (30-120s, not 3-5s)
     4. Consider API-based alternative (Brave Search, Perplexity)
   - Scraping-based MCPs are inherently unreliable for automation
   - API-based MCPs should be preferred for critical workflows

7. **"Connected" ≠ "Tools Available"** (NEW - 2026-01-09)
   - `claude mcp list` shows MCP as "Connected" when server responds
   - This does NOT guarantee tools are available in current session
   - **Observed**: DuckDuckGo tools available, but Brave Search, arXiv, GitHub, Context7, Sequential Thinking tools NOT in session despite "Connected"

   **Root Cause (Research)**:
   - Tool definitions consume significant context tokens before conversation starts
   - Playwright alone: ~13K tokens. Memory+Filesystem+Git+Fetch: ~8K tokens
   - Claude Code may have implicit limits on total tool context
   - GitHub docs mention 128 tool limit; context limits may be lower

   **Workarounds**:
   1. Disable high-token MCPs (Playwright) when not needed
   2. Use selective MCP enabling per task type
   3. Consider consolidating similar tools into fewer MCPs

   **Validation Impact**: Phase 3 (Tool Inventory) must verify tools actually exist in session, not just that MCP is "Connected"

### Validation Results Summary

| MCP | Status | Tier | Key Finding |
|-----|--------|------|-------------|
| Git | PASS | 1 | Reliable, ~2.5K tokens |
| Memory | PASS | 1 | Reliable, ~1.8K tokens |
| Filesystem | PASS | 1 | Reliable, ~2.8K tokens |
| **Brave Search** | **PASS** | 2 | API-based, reliable, ~3K tokens |
| **arXiv** | **PASS** | 2 | Full paper download/read workflow |
| **DateTime** | **PASS** | 2 | Simple, ~1K tokens, IANA timezone |
| **DesktopCommander** | **PASS** | 2 | 30+ tools, ~8K tokens |
| **Wikipedia** | **PASS** | 2 | Clean markdown output, ~2K tokens |
| **Chroma** | **PASS** | 2 | Vector DB with semantic search, ~4K |
| **Perplexity** | **PASS** | 2 | 4 tools (search/ask/research/reason), ~3K |
| **Playwright** | **PASS** | 3 | Browser automation, ~6K tokens |
| **GPTresearcher** | **PASS** | 2 | Deep research, Python 3.13 venv required |
| **Lotus Wisdom** | **PASS** | 3 | Contemplative reasoning, niche |
| DuckDuckGo | **REMOVED** | — | Bot detection blocks all implementations |

**Note**: Brave Search and arXiv were BLOCKED mid-session but PASS after restart (Discovery #7 confirmed).

### Troubleshooting Case Study: DuckDuckGo MCP

**Problem**: All DuckDuckGo searches returned "DDG detected an anomaly" error

**Investigation**:
1. Checked MCP config: `~/.claude.json` showed `npx -y duckduckgo-mcp-server`
2. Identified package: `npm view duckduckgo-mcp-server` → `zhsama/duckduckgo-mcp-server`
3. Found root cause: TypeScript implementation uses `duck-duck-scrape` library which triggers DDG bot detection

**Resolution**:
1. Python version (uvx) also fails — DuckDuckGo server-side detection
2. Added Brave Search MCP as reliable API-based alternative (PASS)
3. **DuckDuckGo MCP REMOVED** — unreliable for automation

**Final Outcome**:
- DuckDuckGo: REMOVED from configuration
- Brave Search: PASS — primary MCP-based search
- arXiv: PASS — academic paper retrieval

**Lesson**: Scraping-based MCPs are unreliable; prefer API-based alternatives

### PR-8.5 Additional Discoveries (2026-01-09)

8. **Perplexity `strip_thinking` Parameter**
   - Deep research tools include `<think>` tags showing reasoning process
   - Setting `strip_thinking=true` removes these, saving significant tokens
   - Quality of answers preserved; only internal reasoning stripped
   - **Recommendation**: Always use `strip_thinking=true` for `perplexity_research` and `perplexity_reason`

9. **GPTresearcher Python Version Requirements**
   - Requires Python 3.13+ for `gpt-researcher>=0.14.0` dependencies
   - System Python may be too old (macOS ships with Python 3.9)
   - **Solution**: Use `uv venv --python 3.13` to create isolated environment
   - MCP command must point to venv Python: `/path/to/.venv/bin/python server.py`

10. **Playwright Accessibility Snapshots**
    - `browser_snapshot` returns YAML accessibility tree, NOT visual screenshot
    - Elements tagged with refs (e.g., `[ref=e6]`) for interaction
    - More efficient than screenshots for automated navigation
    - Use `browser_take_screenshot` only when visual verification needed

11. **Research MCP Complementarity**
    | Tool | Speed | Depth | Best For |
    |------|-------|-------|----------|
    | `perplexity_search` | Fast | Shallow | Quick facts, current events |
    | `perplexity_ask` | Fast | Medium | Q&A with citations |
    | `perplexity_research` | Medium | Deep | Multi-source synthesis |
    | `gptresearcher_quick_search` | Fast | Shallow | Alternative search |
    | `gptresearcher_deep_research` | Slow | Very Deep | Comprehensive research (16+ sources) |
    | `brave_web_search` | Fast | Shallow | Web search fallback |

---

*MCP Validation Harness Pattern — PR-8.4/8.5 (Updated 2026-01-09)*

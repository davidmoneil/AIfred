# Context Budget Management Pattern

**Created**: 2026-01-07
**PR Reference**: PR-8 (Extended Scope)
**Status**: Active

---

## Problem Statement

Claude Code's context window has a hard limit (~200k tokens). When context exceeds this limit, autocompaction triggers, summarizing older context and losing detail. At 232k/200k (116%), Jarvis is operating in degraded mode where:

- Session history gets compressed, losing nuance
- Long sessions lose early context entirely
- MCP tool definitions consume context even when unused
- Plugin/skill definitions add up across multiple sources

**Key Insight**: MCP tool definitions alone consume ~61K tokens (30.5% of budget) whether or not those tools are used.

---

## Context Budget Allocation

### Target Budget Distribution

| Category | Target % | Tokens | Notes |
|----------|----------|--------|-------|
| Conversation | 50% | ~100K | User messages, assistant responses |
| System prompt + CLAUDE.md | 10% | ~20K | Must be concise |
| Always-On MCPs | 15% | ~30K | Core tools only |
| On-Demand MCPs | 10% | ~20K | Loaded per-session |
| Plugins + Skills | 10% | ~20K | Evaluated for value |
| Buffer | 5% | ~10K | Safety margin |

### Current State (Pre-optimization)

| Category | Actual % | Tokens | Issue |
|----------|----------|--------|-------|
| MCP Tools | 30.5% | 61K | Too many always-on |
| CLAUDE.md | 2.6% | 5.2K | Acceptable |
| Unused plugins | ~5% | 10K+ | Wasteful |

---

## MCP Loading Tiers (Revised 2026-01-07)

### Tier 1: Always-On (Minimal Essential)

MCPs that provide core functionality needed in virtually every session. These remain loaded permanently.

| MCP | Tokens | Justification |
|-----|--------|---------------|
| Memory | ~8-15K | Persistent knowledge graph, cross-session recall |
| Filesystem | ~8K | File operations outside workspace |
| Fetch | ~5K | Web content retrieval |
| Git | ~6K | Git operations (core workflow) |

**Total Tier 1**: ~27-34K tokens

### Tier 2: Task-Scoped (Agent-Managed)

MCPs that agents can dynamically **load, use, and unload** based on task requirements. Agents evaluate whether to load these when planning complex tasks.

| MCP | Tokens | Use Case | Unload Trigger |
|-----|--------|----------|----------------|
| Time | ~3K | Timestamps, timezone handling | Task complete |
| GitHub | ~15K | PR work, issue management | PR/issue work done |
| Context7 | ~8K | Documentation lookup | Research phase done |
| Sequential Thinking | ~5K | Complex problem decomposition | Plan finalized |
| DuckDuckGo | ~4K | Web search | Search complete |
| Database MCPs | varies | Data operations | Query complete |
| Specialized MCPs | varies | Domain-specific work | Task complete |

**Agent Loading Protocol**:
1. Agent evaluates task requirements during planning
2. Agent requests MCP load if needed (via `/checkpoint` if not available)
3. Agent performs work with MCP
4. **Evaluation point**: After subtask completion, check if MCP still needed
5. If not needed, agent signals MCP can be unloaded

**Unload Evaluation Points**:
- After each major subtask completion
- When switching task context
- Before session compaction warnings
- On explicit `/context-budget` check

### Tier 3: Triggered (Hook/Command-Invoked Only)

MCPs that are **blacklisted from agent selection**. These only activate when explicitly invoked by a hook, command, or skill. Agents cannot choose to load these autonomously.

| MCP | Tokens | Trigger Mechanism | Blacklist Reason |
|-----|--------|-------------------|------------------|
| Playwright | ~15K | `/browser-test` command, webapp-testing skill | High cost, specialized use |
| BrowserStack | varies | CI/CD hooks | External service, specialized |
| Slack | varies | `/notify` command | Communication channel |
| Google Drive | varies | `/sync-docs` command | Billing implications |
| Google Maps | varies | Location-based hooks | Billing implications |

**Trigger Protocol**:
1. Only specified hooks/commands/skills can invoke Tier 3 MCPs
2. MCP loads, performs specific task, unloads immediately
3. Agents see these MCPs as "unavailable" during planning
4. No autonomous selection permitted

### Loading Protocol Summary

```
Session Start:
1. Load Tier 1 (always, ~30K tokens)
2. All Tier 2 MCPs available but not loaded
3. Tier 3 MCPs blacklisted from agent selection

During Work:
1. Agent plans task, identifies needed Tier 2 MCPs
2. Agent loads MCPs via checkpoint if needed
3. After each subtask: evaluate if MCP still needed
4. Unload MCPs no longer required

Triggered MCPs:
1. Specific hook/command/skill invokes Tier 3 MCP
2. MCP loads, executes, unloads
3. No agent involvement in selection
```

---

## Plugin/Skill Pruning Criteria

### Bundle Overhead (Cannot Remove Individually)

> **Finding (2026-01-07)**: Skills like `algorithmic-art`, `doc-coauthoring`, `slack-gif-creator`, and
> the duplicate `frontend-design` are **bundled within** `document-skills@anthropic-agent-skills`.
> Removing them individually requires uninstalling the entire plugin, losing valuable core skills.

| Bundled Skill | Tokens | Status |
|---------------|--------|--------|
| algorithmic-art | 4.8K | Bundled overhead (unused) |
| doc-coauthoring | 3.8K | Bundled overhead (unused) |
| slack-gif-creator | 1.9K | Bundled overhead (unused) |
| frontend-design | 989 | Duplicate of standalone plugin |

**Total Bundled Overhead**: ~11.5K tokens

**Trade-off Decision**: Keep `document-skills` plugin despite overhead because:
- Core skills (`docx`, `pdf`, `xlsx`, `pptx`) are high-value
- Removing entire plugin loses more functionality than overhead saves
- Future: Request per-skill disable feature from Anthropic

### Duplicate Resolution (Actionable)

| Duplicate | Sources | Resolution |
|-----------|---------|------------|
| frontend-design | claude-code-plugins (990), document-skills (989) | Accept duplication — standalone version takes precedence |

**Note**: Cannot selectively disable the bundled `frontend-design` without plugin modification.

### Consolidation Candidates

Skills that overlap with built-in capabilities:

| Skill | Overlaps With | Action |
|-------|---------------|--------|
| Various doc skills | Write tool | Evaluate per-session need |

---

## CLAUDE.md Optimization

Current size: 5.2K tokens (acceptable but improvable)

### Optimization Strategies

1. **Move details to secondary docs**: Keep CLAUDE.md as index, details in linked files
2. **Remove redundancy**: Several sections repeat information from linked docs
3. **Compress tables**: Use concise format
4. **Remove examples**: Link to examples instead of embedding

### Target Size

- CLAUDE.md: < 3K tokens (40% reduction)
- Pattern: Quick reference + links to detail docs

---

## Implementation Checklist (Aligned with Roadmap)

### PR-8.1: Context Budget Optimization — ✅ COMPLETE (v1.8.0)

- [x] Investigate unused plugins — **FINDING**: bundled in document-skills, cannot remove individually
- [x] Resolve frontend-design duplicate — **FINDING**: accept duplication, standalone takes precedence
- [x] CLAUDE.md refactoring — 78% reduction (510→113 lines)
- [x] Create `CLAUDE-full-reference.md` archive
- [x] Create `/context-budget` command
- [x] Add context budget to `/tooling-health` Executive Summary

### PR-8.2: MCP Loading Tiers — ✅ DESIGN COMPLETE

- [x] Define 3-tier system (Always-On / Task-Scoped / Triggered)
- [x] Document unload evaluation points
- [x] Create plugin-decomposition-pattern.md for future extraction
- [ ] *Enforcement via hooks/commands* — Moved to PR-8.3

**Note**: Claude Code doesn't have native MCP tier enforcement. Implementation requires PR-8.3 dynamic loading protocol.

### PR-8.3: Dynamic Loading Protocol — ✅ COMPLETE

- [x] Update session-start hook to check planned work type from session-state.md
- [x] Add MCP loading suggestions based on work type
- [x] Update `/checkpoint` command to preserve MCP loading state
- [x] Add budget warnings to session-start
- [x] Document MCP enable/disable instructions for tier transitions

### PR-8.4: MCP Validation Harness — PENDING

- [ ] Create standardized MCP validation procedure
- [ ] Token cost measurement per MCP
- [ ] Health + tool invocation tests
- [ ] Dependency-triggered install recommendations

### PR-9 Integration (Brainstorm — Future)

- [ ] Context threshold hook (`context-threshold.js`)
- [ ] Context analyzer agent
- [ ] `/mcp-audit` command (last-use timestamps)
- [ ] `/mcp-unload` command (graceful deactivation)
- [ ] Plugin decomposition execution (extract docx, pdf, xlsx, pptx)

---

## MCP Tier Transition Instructions

### Enabling Tier 2 MCPs (Task-Scoped)

When the session-start hook suggests a Tier 2 MCP:

```bash
# Check current MCP configuration
claude mcp list

# Add a Tier 2 MCP for the current session
claude mcp add <mcp-name>

# Example: Enable GitHub MCP for PR work
claude mcp add github
```

**After enabling**: Restart Claude Code for the MCP to load.

### Disabling Tier 2 MCPs (Reduce Context)

When context budget is high and an MCP is no longer needed:

```bash
# Disable MCPs (adds to disabledMcpServers array)
.claude/scripts/disable-mcps.sh <mcp-name> [mcp-name...]

# Example: Disable Context7 after research phase
.claude/scripts/disable-mcps.sh context7

# Example: Disable multiple MCPs
.claude/scripts/disable-mcps.sh github context7 sequential-thinking
```

**Note**: Changes take effect after `/clear` (validated 2026-01-07).

### Tier 3 MCPs (Triggered Only)

Tier 3 MCPs should NOT be manually enabled. They are invoked by specific commands:

| MCP | Trigger Command | When to Use |
|-----|-----------------|-------------|
| Playwright | `/browser-test` | Browser automation, webapp testing |
| BrowserStack | CI/CD hooks | Cross-browser testing |
| Slack | `/notify` | Team notifications |

**If you need Tier 3 functionality**: Use the trigger command rather than adding the MCP manually.

### Context Budget Workflow

1. **Session Start**: Check suggested MCPs in session-start output
2. **Before Major Work**: Run `/context-budget` to assess headroom
3. **Mid-Session**: If context > 80%, evaluate unloading Tier 2 MCPs
4. **Before Checkpoint**: Document active MCPs in session-state.md
5. **Session End**: MCPs remain for next session unless explicitly removed

### Context Management Workflow (Validated 2026-01-07)

Single workflow for context management with MCP reduction:

```
/context-checkpoint → /exit-session → /clear → resume
```

**Steps**:
1. Run `/context-checkpoint`
   - Creates checkpoint file with work state
   - Evaluates MCPs needed for next steps
   - Runs `disable-mcps.sh` for unneeded MCPs (if approved)
2. Run `/exit-session`
   - Commits checkpoint and session state
   - Displays: "Run /clear to resume"
3. Run `/clear`
   - Clears conversation
   - SessionStart hook loads checkpoint
   - Disabled MCPs not loaded (disabledMcpServers respected)
4. Say "continue" to resume

**Key Discovery**: `/clear` respects `disabledMcpServers` changes — no `exit` + `claude` required.

### Emergency Context Recovery

If context exceeds 100% and autocompaction triggers:

1. Run `/context-checkpoint` immediately
2. Approve MCP reduction recommendations
3. Run `/exit-session` (commits state)
4. Run `/clear`
5. Resume from checkpoint with reduced MCP load

**Hook Support**: The `session-start.sh` hook detects checkpoint files and loads them automatically after `/clear`.

### Helper Scripts

```bash
# Disable specific MCPs
.claude/scripts/disable-mcps.sh <mcp-name> [mcp-name...]

# Enable specific MCPs (or --all)
.claude/scripts/enable-mcps.sh <mcp-name> [mcp-name...]
.claude/scripts/enable-mcps.sh --all

# Show current MCP status
.claude/scripts/list-mcp-status.sh
```

**Legacy scripts** (use `claude mcp remove`, deprecated):
- `adjust-mcp-config.sh` — Use `disable-mcps.sh` instead
- `restore-mcp-config.sh` — Use `enable-mcps.sh` instead

---

## Related Documentation

- @.claude/context/patterns/mcp-loading-strategy.md - Original MCP tiers
- @.claude/context/integrations/capability-matrix.md - Tool selection
- @.claude/context/integrations/overlap-analysis.md - Conflict resolution

---

*Context Budget Management Pattern v1.0 — PR-8 Extended Scope*

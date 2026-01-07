# Tooling Health Report

**Generated**: 2026-01-06 14:26 MST
**Revised**: 2026-01-06 (user feedback incorporated)
**Claude Code Version**: Opus 4.5 (claude-opus-4-5-20251101)
**Workspace**: `/Users/aircannon/Claude/Jarvis`
**Branch**: `Project_Aion`

---

## Executive Summary

| Category | Status | Details |
|----------|--------|---------|
| MCP Servers | ⚠️ PARTIAL | 6/7 Stage 1 connected; tool-level testing required |
| Plugins | ⚠️ ATTENTION | 2/14 PR-5 target installed; path mismatch |
| Skills | ✅ HEALTHY | Session management + anthropic-agent-skills marketplace |
| Built-in Tools | ✅ HEALTHY | All core tools available |
| Subagents | ✅ HEALTHY | 5 subagents available (incl. statusline-setup) |
| Custom Agents | ⚠️ ATTENTION | 4 defined but not recognized by `/agents` |
| Commands | ✅ HEALTHY | 8 project + 50+ built-in commands |

**Overall Health**: ⚠️ PARTIAL - Multiple items require attention for PR-5 completion

---

## Detailed Findings

### 1. MCP Servers

#### Stage 1 Baseline Status

| Server | Status | Token Cost | Tools | Notes |
|--------|--------|------------|-------|-------|
| memory | ✅ Connected | ~8-15K | 8 | Graph empty (0 entities) |
| filesystem | ✅ Connected | ~8K | 13 | Access to Jarvis + Claude dirs |
| fetch | ✅ Connected | ~5K | 1 | Web content fetching |
| time | ✅ Connected | ~3K | 2 | Timezone operations |
| git | ✅ Connected | ~6K | 13 | Repository: Jarvis |
| sequential-thinking | ✅ Connected | ~5K | 1 | Problem decomposition |
| github | ❌ Failed | ~15K | ~20+ | SSE connection failed |

**Stage 1 Coverage**: 6/7 (86%)

#### MCP Tool Inventory (Requires Smoke Testing)

**Memory MCP (8 tools)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `create_entities` | ❌ | Pending | |
| `create_relations` | ❌ | Pending | |
| `add_observations` | ❌ | Pending | |
| `delete_entities` | ❌ | Pending | |
| `delete_observations` | ❌ | Pending | |
| `delete_relations` | ❌ | Pending | |
| `read_graph` | ✅ | GO | Empty graph returned |
| `search_nodes` | ❌ | Pending | |
| `open_nodes` | ❌ | Pending | |

**Filesystem MCP (13 tools)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `read_file` | ❌ | Pending | Deprecated, use read_text_file |
| `read_text_file` | ❌ | Pending | |
| `read_media_file` | ❌ | Pending | |
| `read_multiple_files` | ❌ | Pending | |
| `write_file` | ❌ | Pending | |
| `edit_file` | ❌ | Pending | |
| `create_directory` | ❌ | Pending | |
| `list_directory` | ❌ | Pending | |
| `list_directory_with_sizes` | ❌ | Pending | |
| `directory_tree` | ❌ | Pending | |
| `move_file` | ❌ | Pending | |
| `search_files` | ❌ | Pending | |
| `get_file_info` | ❌ | Pending | |
| `list_allowed_directories` | ❌ | Pending | |

**Fetch MCP (1 tool)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `fetch` | ❌ | Pending | |

**Time MCP (2 tools)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `get_current_time` | ✅ | GO | Returned valid timestamp |
| `convert_time` | ❌ | Pending | |

**Git MCP (13 tools)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `git_status` | ❌ | Pending | |
| `git_diff_unstaged` | ❌ | Pending | |
| `git_diff_staged` | ❌ | Pending | |
| `git_diff` | ❌ | Pending | |
| `git_commit` | ❌ | Pending | |
| `git_add` | ❌ | Pending | |
| `git_reset` | ❌ | Pending | |
| `git_log` | ❌ | Pending | |
| `git_create_branch` | ❌ | Pending | |
| `git_checkout` | ❌ | Pending | |
| `git_show` | ❌ | Pending | |
| `git_branch` | ❌ | Pending | |

**Sequential Thinking MCP (1 tool)**:
| Tool | Tested | Status | Notes |
|------|--------|--------|-------|
| `sequentialthinking` | ❌ | Pending | |

**GitHub MCP (connection failed - tools not available)**

> **Action Required**: Create parallel tracking document `.claude/reports/mcp-tool-testing.md` for ongoing tool validation and issue tracking.

#### Memory MCP Validation Test

Per `.claude/context/integrations/memory-usage.md`, the Memory MCP validation should test:

```
Validation Test Procedure:
1. Create entity: type=Decision, name="Test_Validation", observations=["Smoke test for PR-5"]
2. Create entity: type=Lesson, name="Test_Lesson", observations=["Learning from validation"]
3. Create relation: from="Test_Validation" to="Test_Lesson" type="led_to"
4. Search nodes: query="Test"
5. Read graph: verify 2 entities, 1 relation
6. Delete entities: ["Test_Validation", "Test_Lesson"]
7. Read graph: verify empty

Expected: All operations succeed, graph returns to empty state
```

---

### 2. Plugins

#### Current Installation Status

| Plugin | Scope | Version | Path Status |
|--------|-------|---------|-------------|
| github | project | 6d3752c | ❌ Wrong path |
| commit-commands | project | 6d3752c | ❌ Wrong path |

**Path Issue**: Registered to `/Users/aircannon/Documents/Jarvis`, current workspace is `/Users/aircannon/Claude/Jarvis`

#### PR-5 Target Plugin List

**Install for PR-5 (Y)**:
| Plugin | Status | Purpose | Priority |
|--------|--------|---------|----------|
| context7 | ❌ Not installed | Upstash context management | HIGH |
| github | ⚠️ Wrong path | GitHub integration | HIGH |
| gitlab | ❌ Not installed | GitLab integration | MEDIUM |
| playwright | ❌ Not installed | Browser automation | MEDIUM |
| agent-sdk-dev | ❌ Not installed | Agent SDK verification | HIGH |
| code-review | ❌ Not installed | Automated PR review | HIGH |
| commit-commands | ⚠️ Wrong path | Git workflow | HIGH |
| explanatory-output-style | ❌ Not installed | Output formatting | LOW |
| feature-dev | ❌ Not installed | Feature development | HIGH |
| frontend-design | ❌ Not installed | Frontend design tools | MEDIUM |
| hookify | ❌ Not installed | Hook creation | MEDIUM |
| plugin-dev | ❌ Not installed | Plugin development | LOW |
| ralph-loop | ❌ Not installed | Iterative refinement | MEDIUM |
| security-guidance | ❌ Not installed | Security reminders | HIGH |

**Evaluate for Future (?) - Document but don't install**:
| Plugin | Purpose | Notes |
|--------|---------|-------|
| firebase | Firebase integration | Evaluate when needed |
| linear | Linear.app integration | Evaluate when needed |
| serena | Unknown | Research required |
| slack | Slack integration | Evaluate when needed |
| stripe | Stripe integration | Evaluate when needed |
| supabase | Supabase integration | Evaluate when needed |
| lua-lsp | Lua language server | If Lua development needed |
| pr-review-toolkit | PR review tools | May overlap with code-review |
| pyright-lsp | Python language server | If Python development needed |
| typescript-lsp | TypeScript language server | If TS development needed |

**Do Not Install (X)**:
| Plugin | Reason |
|--------|--------|
| asana | Not relevant to Jarvis scope |
| greptile | Not relevant |
| laravel-boost | PHP-specific |
| clangd-lsp | C/C++-specific |
| csharp-lsp | C#-specific |
| example-plugin | Template only |
| gopls-lsp | Go-specific |
| jdtls-lsp | Java-specific |
| learning-output-style | Not needed |
| php-lsp | PHP-specific |
| rust-analyzer-lsp | Rust-specific |
| swift-lsp | Swift-specific |

---

### 3. Skills

#### Installed Skills

| Skill | Location | Purpose |
|-------|----------|---------|
| session-management | `.claude/skills/session-management/SKILL.md` | Session lifecycle management |

#### Marketplace Added

- `anthropic-agent-skills` - Added via `/plugin marketplace add anthropics/skills`

---

### 4. Available Commands

#### Project Commands (8)

| Command | Purpose | Stoppage Hook Required |
|---------|---------|------------------------|
| `/checkpoint` | Save session state for MCP restart | No |
| `/design-review` | PARC pattern design review | No |
| `/end-session` | Clean session exit with documentation | **Yes*** |
| `/health-report` | Infrastructure health aggregation | No |
| `/setup` | Initial configuration wizard | **Yes*** |
| `/setup-readiness` | Validate setup completion | No |
| `/sync-aifred-baseline` | Analyze AIfred baseline changes | No |
| `/tooling-health` | Tooling validation | No |

#### Built-in Claude Code Commands (50+)

**Core Workflow**:
| Command | Purpose | Stoppage Hook Required |
|---------|---------|------------------------|
| `/add-dir` | Add a new working directory | No |
| `/agents` | Manage agent configurations | No |
| `/clear` | Clear conversation history | No |
| `/compact` | Summarize and clear history | No |
| `/context` | Visualize context usage | No |
| `/doctor` | Diagnose installation | No |
| `/export` | Export conversation | No |
| `/help` | Show help | No |
| `/hooks` | Manage hook configurations | No |
| `/mcp` | Manage MCP servers | No |
| `/memory` | Edit Claude memory files | No |
| `/model` | Set AI model | No |
| `/output-style` | Set output style | No |
| `/plan` | View session plan | No |
| `/plugin` | Manage plugins | No |
| `/pr-comments` | Get PR comments | No |
| `/release-notes` | View release notes | No |
| `/rename` | Rename conversation | No |
| `/resume` | Resume conversation | No |
| `/review` | Review a PR | No |
| `/rewind` | Restore to previous point | No |
| `/sandbox` | Configure sandbox | No |
| `/security-review` | Security review | No |
| `/skills` | List skills | No |
| `/stats` | Usage statistics | No |
| `/status` | Show status | No |
| `/tasks` | Manage background tasks | No |
| `/todos` | List todo items | No |
| `/usage` | Show plan usage | No |
| `/vim` | Toggle vim mode | No |

**Require User Approval (Stoppage Hooks)**:
| Command | Purpose | Risk |
|---------|---------|------|
| `/config`* | Open config panel | Settings changes |
| `/exit`* | Exit REPL | Session termination |
| `/extra-usage`* | Configure extra usage | Cost implications |
| `/feedback`* | Submit feedback | External communication |
| `/init`* | Initialize CLAUDE.md | File creation |
| `/login`* | Sign in | Authentication |
| `/logout`* | Sign out | Authentication |
| `/mobile`* | Show mobile QR | External app |
| `/passes`* | Share free week | Account feature |
| `/permissions`* | Manage permissions | Security |
| `/privacy-settings`* | Update privacy | Privacy |
| `/stickers`* | Order stickers | Purchase |
| `/terminal-setup`* | Terminal configuration | System settings |
| `/theme`* | Change theme | UI settings |
| `/upgrade`* | Upgrade plan | Account/billing |

**IDE/Integration**:
| Command | Purpose |
|---------|---------|
| `/chrome` | Chrome integration settings |
| `/ide` | IDE integrations status |
| `/install-github-app` | Setup GitHub Actions |
| `/install-slack-app` | Install Slack app |
| `/remote-env` | Configure remote environment |
| `/statusline` | Status line UI setup |
| `/fetch:fetch` | MCP fetch command |

---

### 5. Subagents

#### Built-in Subagents

| Subagent | Status | Purpose |
|----------|--------|---------|
| Explore | ✅ Available | Fast codebase exploration |
| Plan | ✅ Available | Implementation planning |
| claude-code-guide | ✅ Available | Documentation lookup |
| general-purpose | ✅ Available | Complex multi-step tasks |
| **statusline-setup** | ✅ Available | Configure status line UI settings |

> **Note**: `statusline-setup` was previously omitted from reporting. It provides specialized configuration for Claude Code's status line display.

---

### 6. Custom Agents (Jarvis-Specific)

#### Current State

The `/agents` command shows **no agents found**, yet `.claude/agents/` contains:

| File | Agent Name | Purpose | Status |
|------|------------|---------|--------|
| `_template-agent.md` | Template | Agent template | N/A |
| `deep-research.md` | deep-research | In-depth topic investigation | ⚠️ Not recognized |
| `docker-deployer.md` | docker-deployer | Docker service deployment | ⚠️ Not recognized |
| `service-troubleshooter.md` | service-troubleshooter | Infrastructure diagnosis | ⚠️ Not recognized |
| `memory-bank-synchronizer.md` | memory-bank-synchronizer | Documentation sync | ⚠️ Not recognized |

#### Analysis

These markdown files define agent prompts and workflows but are **not in the format Claude Code's `/agents` command expects**. They appear to be:
- AIfred-originated documentation
- Intended for use via `Task` tool with `subagent_type` parameter
- Not registered as formal Claude Code agents

#### Unification Proposal

**Option A: Convert to Claude Code Agent Format**
- Research the official agent registration format
- Convert existing markdown definitions to proper agent configs
- Register via `/agents` command

**Option B: Create Skill Wrappers**
- Keep markdown definitions as documentation
- Create skills that invoke agents via Task tool
- Example: `/skill deep-research "topic"` invokes Task with the agent prompt

**Option C: Hybrid Approach (Recommended)**
- Document agents in markdown (current state)
- Create a skill or command that reads agent definitions and invokes them
- Register key agents with Claude Code if format is discovered
- Maintain backward compatibility with AIfred patterns

**Action Required**: Research Claude Code agent registration format and propose migration path in PR-5.

---

### 7. Feature Expansion Trials (PR-5)

#### Mobile/Voice Integration

| Project | Purpose | GitHub URL | Priority |
|---------|---------|------------|----------|
| **happy** | Interact with Claude Code from iPhone | https://github.com/slopus/happy | HIGH |
| **voicemode** | Voice-talk with Claude Code CLI | https://github.com/mbailey/voicemode | HIGH |

**Recommended Actions**:
1. Clone and evaluate both projects
2. Document installation and configuration
3. Test integration with Jarvis workspace
4. Add to `.claude/context/integrations/` if viable

---

## Issues Requiring Attention

### Issue #1: GitHub MCP Connection Failed

**Severity**: `[!] HIGH`

#### Assessment

The GitHub MCP server is configured to connect via SSE (Server-Sent Events) to `https://api.githubcopilot.com/mcp/`. This connection failed, which means:

- Cannot use GitHub MCP tools for repository management
- Cannot access code security scanning (MCP-exclusive feature)
- Cannot automate GitHub workflows via MCP
- Must fall back to `gh` CLI for all GitHub operations

**Root Cause Analysis**:

The SSE remote connection method requires GitHub Copilot authentication. Possible issues:
1. GitHub Copilot subscription not active or not linked
2. Authentication token expired or missing
3. Network/firewall blocking SSE connections
4. GitHub API rate limiting

**Impact**:
- Reduces Stage 1 baseline coverage from 100% to 86%
- Limits automation capabilities for complex GitHub workflows
- `gh` CLI fallback is available but less integrated

#### Recommended Plan

**Option A: OAuth via GitHub Copilot (Recommended if you have Copilot)**

```bash
# Step 1: Verify GitHub Copilot is active
gh auth status

# Step 2: Re-add the GitHub MCP with OAuth
claude mcp remove github
claude mcp add github --remote https://api.githubcopilot.com/mcp/

# Step 3: Follow OAuth prompts in browser

# Step 4: Verify connection
claude mcp list
```

**Option B: Personal Access Token (PAT)**

```bash
# Step 1: Create a PAT at https://github.com/settings/tokens
# Required scopes: repo, read:org, read:user, notifications

# Step 2: Set environment variable
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# Step 3: Add to shell profile for persistence
echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"' >> ~/.zshrc

# Step 4: Re-add GitHub MCP with Docker
claude mcp remove github
claude mcp add github -- docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  ghcr.io/github/github-mcp-server

# Step 5: Verify
claude mcp list
```

**Option C: Accept Fallback (No Action)**

If GitHub MCP is not critical:
- Continue using `gh` CLI for GitHub operations
- Document this as an accepted limitation
- Stage 1 coverage remains at 86%

**Recommendation**: Try Option A first. If you have GitHub Copilot, this should work seamlessly. Fall back to Option B if OAuth doesn't work.

---

### Issue #2: Plugin Path Mismatch + Missing PR-5 Plugins

**Severity**: `[!] HIGH`

#### Assessment

**Path Mismatch**:
- Registered Path: `/Users/aircannon/Documents/Jarvis`
- Current Workspace: `/Users/aircannon/Claude/Jarvis`

**Missing Plugins**: 12 of 14 PR-5 target plugins not installed.

#### Recommended Plan

```bash
# Step 1: Remove old registrations
cd /Users/aircannon/Claude/Jarvis
claude plugins uninstall github
claude plugins uninstall commit-commands

# Step 2: Install all PR-5 plugins (HIGH priority first)
claude plugins install commit-commands
claude plugins install github
claude plugins install code-review
claude plugins install feature-dev
claude plugins install security-guidance
claude plugins install agent-sdk-dev
claude plugins install context7

# Step 3: Install MEDIUM priority
claude plugins install gitlab
claude plugins install playwright
claude plugins install frontend-design
claude plugins install hookify
claude plugins install ralph-loop

# Step 4: Install LOW priority
claude plugins install explanatory-output-style
claude plugins install plugin-dev

# Step 5: Verify
cat ~/.claude/plugins/installed_plugins.json
```

---

### Issue #3: Memory MCP Empty + Validation Required

**Severity**: `[~] MEDIUM`

#### Assessment

Memory MCP connected but contains no data. Validation test per `memory-usage.md` not yet executed.

#### Recommended Plan

**Step 1: Run Validation Test**

```
1. Create test entities:
   - type=Decision, name="Test_Validation"
   - type=Lesson, name="Test_Lesson"
2. Create relation: Test_Validation → Test_Lesson
3. Search and verify
4. Delete test entities
5. Verify clean state
```

**Step 2: Seed Baseline Entities**

Per memory-usage.md entity types:
```
Entities to create:
- Event: "Jarvis_v1.5.0_Release" - observations: ["Released 2026-01-06", "PR-5 Core Tooling"]
- Decision: "Stage1_MCP_Selection" - observations: ["7 MCPs chosen for baseline"]
- Lesson: "Plugin_Path_Migration" - observations: ["Path changes require plugin re-registration"]
- Relationship: Jarvis → Project_Aion (type: "part_of")
```

---

### Issue #4: Custom Agents Not Recognized

**Severity**: `[~] MEDIUM`

#### Assessment

Four custom agents defined in `.claude/agents/` but `/agents` command shows none found.

#### Recommended Plan

1. Research Claude Code agent registration format
2. Determine if markdown definitions can be converted
3. Create migration path for AIfred-style agents
4. Document hybrid approach for PR-5

---

### Issue #5: MCP Tool-Level Testing Required

**Severity**: `[~] MEDIUM`

#### Assessment

Only 2 of 38+ MCP tools have been smoke tested. Full go/no-go validation needed.

#### Recommended Plan

1. Create `.claude/reports/mcp-tool-testing.md` tracking document
2. Execute smoke test for each tool
3. Document any issues or behavioral concerns
4. Flag tools that don't conform to Jarvis design patterns

---

### Issue #6: Feature Expansion Trials

**Severity**: `[-] LOW`

#### Assessment

Two promising integrations identified for mobile/voice interaction.

#### Recommended Plan

1. Clone repositories:
   ```bash
   cd /Users/aircannon/Claude
   git clone https://github.com/slopus/happy
   git clone https://github.com/mbailey/voicemode
   ```
2. Evaluate requirements and compatibility
3. Test with Jarvis workspace
4. Document in `.claude/context/integrations/`

---

## Stage 1 Baseline Summary

### Current State

```
MCP Servers:     6/7  (86%)  - GitHub MCP failed
MCP Tools:       2/38 (5%)   - Tool-level testing incomplete
Plugins:         2/14 (14%)  - PR-5 target plugins
Skills:          1/1  (100%) - Session management
Commands:        8/8  (100%) - Project commands
Built-in Tools:  10/10 (100%)
Subagents:       5/5  (100%) - Including statusline-setup
Custom Agents:   0/4  (0%)   - Not recognized by /agents
```

### PR-5 Target State

```
MCP Servers:     7/7   (100%) - All Stage 1 MCPs connected
MCP Tools:       38/38 (100%) - All tools smoke tested
Plugins:         14/14 (100%) - All PR-5 plugins installed
Skills:          1/1   (100%) - Session management
Commands:        8/8   (100%) - Project commands
Built-in Tools:  10/10 (100%)
Subagents:       5/5   (100%)
Custom Agents:   4/4   (100%) - Recognized and documented
Feature Trials:  2/2   (100%) - happy + voicemode evaluated
```

### Action Items Summary

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| `[!] HIGH` | Fix GitHub MCP authentication | 10 min | Enables GitHub automation |
| `[!] HIGH` | Install 12 missing PR-5 plugins | 15 min | Full plugin baseline |
| `[~] MEDIUM` | Run Memory MCP validation test | 10 min | Validates memory operations |
| `[~] MEDIUM` | Create MCP tool testing tracker | 30 min | Systematic tool validation |
| `[~] MEDIUM` | Research agent registration format | 30 min | Agent unification path |
| `[~] MEDIUM` | Document stoppage hooks for commands | 20 min | Safety guardrails |
| `[-] LOW` | Evaluate happy/voicemode integrations | 60 min | Mobile/voice capability |
| `[-] LOW` | Seed Memory MCP baseline entities | 15 min | Cross-session memory |

---

## Appendix A: MCP Server Configuration

```
memory: npx -y @modelcontextprotocol/server-memory
filesystem: npx -y @modelcontextprotocol/server-filesystem /Users/aircannon/Claude/Jarvis /Users/aircannon/Claude
fetch: uvx mcp-server-fetch
time: uvx mcp-server-time
git: uvx mcp-server-git --repository /Users/aircannon/Claude/Jarvis
sequential-thinking: npx -y @modelcontextprotocol/server-sequential-thinking
github: https://api.githubcopilot.com/mcp/ (SSE) - FAILED
```

---

## Appendix B: Plugin Installation JSON (Current)

```json
{
  "version": 2,
  "plugins": {
    "github@claude-plugins-official": [
      {
        "scope": "project",
        "projectPath": "/Users/aircannon/Documents/Jarvis",
        "version": "6d3752c000e2",
        "installedAt": "2026-01-02T01:39:35.191Z"
      }
    ],
    "commit-commands@claude-plugins-official": [
      {
        "scope": "project",
        "projectPath": "/Users/aircannon/Documents/Jarvis",
        "version": "6d3752c000e2",
        "installedAt": "2026-01-02T01:39:40.685Z"
      }
    ]
  }
}
```

---

## Appendix C: Custom Agent Definitions

| Agent | File | Purpose | Invocation |
|-------|------|---------|------------|
| deep-research | `.claude/agents/deep-research.md` | In-depth investigation | `Task(subagent_type: deep-research)` |
| docker-deployer | `.claude/agents/docker-deployer.md` | Docker deployment | `Task(subagent_type: docker-deployer)` |
| service-troubleshooter | `.claude/agents/service-troubleshooter.md` | Service diagnosis | `Task(subagent_type: service-troubleshooter)` |
| memory-bank-synchronizer | `.claude/agents/memory-bank-synchronizer.md` | Doc sync | `Task(subagent_type: memory-bank-synchronizer)` |

---

## Related Documentation

- `.claude/context/integrations/capability-matrix.md` - Task to tool selection
- `.claude/context/integrations/mcp-installation.md` - MCP installation procedures
- `.claude/context/integrations/overlap-analysis.md` - Tool overlap resolution
- `.claude/context/integrations/memory-usage.md` - Memory MCP usage patterns
- `.claude/context/patterns/memory-storage-pattern.md` - Memory usage guidance
- `.claude/commands/health-report.md` - Infrastructure health command

---

## Next Steps (Pending User Approval)

1. **Immediate**: Fix GitHub MCP + reinstall plugins to correct path
2. **PR-5 Core**: Install remaining 12 plugins, run MCP tool tests
3. **PR-5 Extended**: Agent unification, feature trials, command guardrails
4. **Documentation**: Create mcp-tool-testing.md, update capability matrix

---

*Report generated by `/tooling-health` command*
*PR-5 Core Tooling Baseline*
*Revised with user feedback 2026-01-06*

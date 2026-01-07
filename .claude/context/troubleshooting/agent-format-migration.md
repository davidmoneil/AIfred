# Agent Format Migration Guide

**Created**: 2026-01-06
**Issue**: Custom agents not recognized by `/agents` command
**Status**: RESEARCH COMPLETE — Migration plan defined

---

## Problem

Custom agents defined in `.claude/agents/` are not recognized by Claude Code's `/agents` command:

| Agent | File | Recognition |
|-------|------|-------------|
| docker-deployer | `.claude/agents/docker-deployer.md` | Not recognized |
| service-troubleshooter | `.claude/agents/service-troubleshooter.md` | Not recognized |
| deep-research | `.claude/agents/deep-research.md` | Not recognized |
| memory-bank-synchronizer | `.claude/agents/memory-bank-synchronizer.md` | Not recognized |

---

## Root Cause Analysis

### Current Jarvis Agent Format

Jarvis uses an **extended markdown format** without YAML frontmatter:

```markdown
# Agent: Deep Research

## Metadata
- **Purpose**: In-depth topic investigation with citations
- **Can Call**: none
- **Memory Enabled**: Yes
- **Session Logging**: Yes

## Agent Prompt

You are the Deep Research agent...
```

### Claude Code Expected Format

Claude Code expects **YAML frontmatter** with specific required fields:

```markdown
---
name: deep-research
description: In-depth topic investigation with citations and analysis
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
model: sonnet
---

You are the Deep Research agent...
```

### Key Differences

| Aspect | Jarvis Format | Claude Code Format |
|--------|---------------|-------------------|
| Metadata location | `## Metadata` section | YAML frontmatter |
| Name field | Header: `# Agent: Name` | `name:` in frontmatter |
| Description | `**Purpose**:` bullet | `description:` in frontmatter |
| Tools | Not specified | `tools:` in frontmatter |
| Model | Not specified | `model:` in frontmatter |
| System prompt | Under `## Agent Prompt` | Body after frontmatter |

---

## Claude Code Agent Schema

### Required Fields

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Lowercase identifier with hyphens (e.g., `deep-research`) |
| `description` | string | When to invoke this agent (used for auto-selection) |

### Optional Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `tools` | string | All tools | Comma-separated tool list |
| `model` | string | Inherit | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | string | default | Permission handling mode |
| `skills` | string | None | Comma-separated skills to auto-load |
| `color` | string | None | Display color in UI |

---

## Migration Options

### Option A: Convert to YAML Frontmatter (Recommended)

**Effort**: ~30 minutes per agent
**Benefit**: Full Claude Code integration, `/agents` recognition

**Process**:
1. Add YAML frontmatter with required fields
2. Move system prompt to body
3. Keep extended documentation as comments or separate files

**Example Migration**:

```markdown
---
name: deep-research
description: Conduct thorough technical research with citations, comparisons, and actionable recommendations
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch, TodoWrite
model: sonnet
---

You are the Deep Research agent. You conduct thorough investigations on technical topics, providing well-sourced findings with proper citations.

## Your Role
- Answer specific technical questions
- Compare tools and approaches
- Gather best practices
- Provide actionable recommendations

## Research Workflow

1. **Question Analysis**: Understand scope and constraints
2. **Source Gathering**: Official docs, articles, repos
3. **Information Analysis**: Extract facts, note consensus
4. **Synthesis**: Combine findings, form recommendations
5. **Report Generation**: Structure with citations

## Output Format

Deliver research reports with:
- Executive Summary
- Key Findings with citations
- Comparison tables (if applicable)
- Recommendations
- Action items
- Sources
```

### Option B: Create Plugin Wrapper

**Effort**: 2-4 hours
**Benefit**: Distributable, versioned, marketplace-ready

**Process**:
1. Create plugin structure in `.claude/plugins/jarvis-agents/`
2. Add `plugin.json` manifest
3. Move agents to `agents/` subdirectory
4. Add YAML frontmatter to each

### Option C: Hybrid Approach

**Effort**: ~15 minutes per agent
**Benefit**: Minimal changes, preserves documentation

**Process**:
1. Add YAML frontmatter to existing files
2. Keep extended documentation below the frontmatter
3. Claude Code reads frontmatter, ignores extended sections

---

## Recommended Migration: Option A

### Migration Steps

1. **Backup current agents**:
   ```bash
   cp -r .claude/agents .claude/agents.backup
   ```

2. **Convert each agent**:
   - Extract name, description from Metadata
   - Determine tool requirements
   - Select appropriate model
   - Add YAML frontmatter
   - Consolidate system prompt

3. **Preserve extended documentation**:
   - Move workflow details to system prompt
   - Keep memory patterns, output formats
   - Archive original format in `.claude/agents/archive/`

4. **Verify recognition**:
   ```bash
   # After restart or /agents reload
   /agents  # Should show all 4 agents
   ```

5. **Update CLAUDE.md**:
   - Document new invocation pattern
   - Update agent documentation references

---

## Agent Migration Specifications

### docker-deployer

```yaml
---
name: docker-deployer
description: Deploy and configure Docker services with validation, conflict detection, health verification, and automatic documentation
tools: Read, Grep, Glob, Bash, Write, Edit, TodoWrite
model: sonnet
---
```

### service-troubleshooter

```yaml
---
name: service-troubleshooter
description: Systematically diagnose infrastructure and service issues with structured investigation and root cause analysis
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch, TodoWrite
model: sonnet
---
```

### deep-research

```yaml
---
name: deep-research
description: Conduct thorough technical research with citations, multi-source validation, and actionable recommendations
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch, TodoWrite
model: sonnet
---
```

### memory-bank-synchronizer

```yaml
---
name: memory-bank-synchronizer
description: Sync documentation with code changes while preserving user content like todos, decisions, and notes
tools: Read, Grep, Glob, Write, Edit, TodoWrite
model: sonnet
---
```

---

## Post-Migration Verification

After migration, verify:

1. **Agent Recognition**:
   ```
   /agents  # Should list all 4 agents
   ```

2. **Agent Invocation**:
   ```
   /docker-deployer "Deploy nginx"
   /deep-research "Compare Redis vs Memcached"
   ```

3. **Tool Access**:
   - Each agent should have access to specified tools
   - Verify no permission issues

4. **Memory Integration**:
   - Ensure agents can still access `.claude/agents/memory/`
   - Update memory paths in system prompts if needed

---

## Related Documentation

- Claude Code Subagents: https://code.claude.com/docs/en/sub-agents.md
- Plugin Agents: https://code.claude.com/docs/en/plugins.md
- `.claude/agents/` — Current agent definitions
- `.claude/context/patterns/agent-selection-pattern.md` — Agent selection guide

---

*PR-5 Core Tooling Baseline — Agent Format Migration Guide v1.0*

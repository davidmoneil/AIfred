# Design Patterns Index

This directory contains reusable design patterns for AI infrastructure.

## Core Patterns (Foundation)

### Agent & Skill Architecture
- **agent-selection-pattern.md** - Choose between custom agents, built-in subagents, skills, or direct tools
- **agent-invocation-pattern.md** - Agent definition and invocation guidelines
- **skill-architecture-pattern.md** - Required vs optional skill components
- **command-invocation-pattern.md** - When/how commands invoke skills/CLI

### Capability & Execution
- **capability-layering-pattern.md** - Scripts over LLM - 5-layer architecture (IDEA → CODE → CLI → PROMPT → USER)
- **code-before-prompts-pattern.md** - Deterministic code, AI for intelligence
- **autonomous-execution-pattern.md** - Scheduled Claude jobs with permission tiers

### Memory & Context
- **memory-storage-pattern.md** - When to store in Memory MCP (decisions, relationships, events, lessons)
- **mcp-loading-strategy.md** - Always-On vs On-Demand vs Isolated MCPs
- **prompt-design-review.md** (PARC) - Prompt → Assess → Relate → Create
- **prompt-enhancement-pattern.md** - Hook-based guidance injection (LSP, MCP)

## Infrastructure Patterns

### Service Architecture
- **service-architecture-pattern.md** - TypeScript service patterns (pg-boss, MCP exposure, n8n integration)
- **health-endpoint-pattern.md** - Service health check standards

### Collaboration & Integration
- **obsidian-collaboration-pattern.md** - Session artifacts in Obsidian, dual output
- **cross-project-commit-tracking.md** - Track commits across multiple projects
- **worktree-shell-functions.md** - Git worktree workflow shortcuts

### Security & Authentication
- **authentik-automation-pattern.md** - Token-based automation access
- **secret-management-pattern.md** - SOPS + age encryption for Docker secrets

### Evaluation & Quality
- **external-tool-evaluation-pattern.md** - Systematic tool/project evaluation framework

### Configuration & Environment
- **environment-profile-pattern.md** - Composable profile layers (homelab, development, production)

### Execution Patterns
- **fresh-context-pattern.md** - Execute tasks in fresh Claude instances (no context pollution)

## Testing & Validation
- **sync-validation-test.md** - Test pattern for synchronization

---

## Pattern Usage

**When to create a pattern**:
- You've solved the same problem 3+ times
- The solution involves multiple steps or decisions
- The solution could benefit others in similar situations

**Pattern structure**:
```markdown
# Pattern Name

**Status**: Active | Draft | Deprecated
**Created**: YYYY-MM-DD
**Purpose**: One-line description

## Overview
...

## When to Use
...

## Implementation
...

## Examples
...
```

**Pattern categories**:
- **Core**: Fundamental architectural decisions
- **Infrastructure**: Service deployment and management
- **Collaboration**: Team workflows and integration
- **Security**: Authentication and authorization

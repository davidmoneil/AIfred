# Agent Selection Pattern

**Last Updated**: 2026-01-01
**Status**: Active
**Purpose**: Decision framework for choosing between custom agents, built-in subagents, skills, and direct tools

---

## Overview

This pattern provides a structured approach to selecting the right automation mechanism for any task. Your hub infrastructure offers multiple automation options with different characteristics:

1. **Custom Agents** (`/agent <name>`) - Your specialized agents with persistent memory
2. **Built-in Subagents** (Task tool) - Claude Code plugin-based specialized agents
3. **Skills** (`/skill-name`) - Quick slash commands for specific tasks
4. **Direct Tools** - MCP tools, Bash, Read, Write, etc.

Understanding when to use each maximizes efficiency and produces better results.

---

## Quick Decision Matrix

| Criteria | Custom Agent | Built-in Subagent | Skill | Direct Tool |
|----------|--------------|-------------------|-------|-------------|
| **Task Steps** | 5+ complex steps | 3-10 specialized steps | 1-3 steps | 1 step |
| **Learning Needed** | Yes - improves over time | No | No | No |
| **Context Isolation** | Full isolation | Full isolation | Same context | Same context |
| **Persistence** | Memory + results files | None | None | None |
| **Invocation** | `/agent <name>` | Automatic via Task | `/skill-name` | Direct call |
| **Best For** | Recurring complex tasks | Code/architecture work | Quick operations | Simple queries |

---

## Built-in Subagents Reference

These are **automatically available** via the Task tool (invoked when appropriate):

### Core Subagents

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `Explore` | Fast codebase exploration | Finding files, searching code, understanding architecture |
| `Plan` | Software architect | Designing implementation strategies |
| `claude-code-guide` | Documentation lookup | Questions about Claude Code, Agent SDK, API |
| `general-purpose` | Multi-step research | Complex questions requiring multiple searches |

### Feature Development (feature-dev plugin)

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `feature-dev:code-architect` | Design feature architectures | Before implementing new features |
| `feature-dev:code-explorer` | Analyze existing features | Understanding code before modifying |
| `feature-dev:code-reviewer` | Review code quality | After significant code changes |

### Hookify Plugin

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `hookify:conversation-analyzer` | Find behaviors for hooks | Creating prevention rules from patterns |

### Agent SDK Development

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `agent-sdk-dev:agent-sdk-verifier-py` | Verify Python SDK apps | After creating/modifying Python agents |
| `agent-sdk-dev:agent-sdk-verifier-ts` | Verify TypeScript SDK apps | After creating/modifying TypeScript agents |

### Infrastructure Validation

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `project-plan-validator` | Validate plans against infrastructure | Before major infrastructure changes |

---

## Custom Agents Reference

These are **your specialized agents** in `.claude/agents/`:

| Agent | Purpose | Invoke With |
|-------|---------|-------------|
| `deep-research` | Web research with multi-source validation | `/agent deep-research "topic"` |
| `service-troubleshooter` | Systematic service diagnosis | `/agent service-troubleshooter "issue"` |
| `docker-deployer` | Guided Docker deployment | `/agent docker-deployer "service"` |
| `ollama-manager` | Local Ollama LLM management | `/agent ollama-manager` |
| `plex-troubleshoot` | Plex Media Server diagnosis | `/agent plex-troubleshoot` |
| `code-analyzer` | Code analysis | `/agent code-analyzer` |
| `code-implementer` | Code implementation | `/agent code-implementer` |
| `code-tester` | Test generation | `/agent code-tester` |

---

## Decision Flow

```
Task Received
     │
     ▼
┌─────────────────────────────────────────────────┐
│ Is this a simple, one-step operation?           │
│ (status check, file read, quick search)         │
└─────────────────────────────────────────────────┘
     │ Yes                              │ No
     ▼                                  ▼
 Direct Tool                ┌─────────────────────────────────────────────────┐
                            │ Does a skill/slash command exist for this?      │
                            │ (check /help or available skills)               │
                            └─────────────────────────────────────────────────┘
                                 │ Yes                              │ No
                                 ▼                                  ▼
                              Use Skill            ┌─────────────────────────────────────────────────┐
                                                   │ Is this code/architecture work?                 │
                                                   │ (feature design, code review, implementation)   │
                                                   └─────────────────────────────────────────────────┘
                                                        │ Yes                              │ No
                                                        ▼                                  ▼
                                              Built-in Subagent    ┌─────────────────────────────────────────────────┐
                                              (feature-dev:*)      │ Will this task repeat? Need learning/memory?    │
                                                                   └─────────────────────────────────────────────────┘
                                                                        │ Yes                              │ No
                                                                        ▼                                  ▼
                                                                   Custom Agent            Built-in Subagent
                                                                   (/agent)               (Explore, Plan, etc.)
```

---

## Use Case Examples

### Use Custom Agent (`/agent`)

**Scenario**: "Research Docker networking best practices for home lab"
```bash
/agent deep-research "Docker networking best practices for home lab production"
```
**Why**: Benefits from persistent memory, produces polished results file, task will repeat

**Scenario**: "Troubleshoot why n8n can't connect to postgres"
```bash
/agent service-troubleshooter "n8n can't connect to postgres"
```
**Why**: Uses diagnostic decision tree, stores learnings for future similar issues

### Use Built-in Subagent (Automatic)

**Scenario**: "Design the architecture for a new user authentication feature"
- System automatically uses `feature-dev:code-architect`
**Why**: Specialized for feature design with blueprint output

**Scenario**: "Review the code I just wrote for security issues"
- System automatically uses `feature-dev:code-reviewer`
**Why**: Confidence-based filtering for high-priority issues

**Scenario**: "Find all files that handle API routing"
- System automatically uses `Explore` subagent
**Why**: Fast pattern matching and codebase navigation

### Use Skill/Slash Command

**Scenario**: "Create a commit for my changes"
```bash
/commit
```
**Why**: Quick, single-purpose operation

**Scenario**: "Check infrastructure health"
```bash
/check-health
```
**Why**: Defined workflow, immediate result needed

### Use Direct Tools

**Scenario**: "Show me the docker containers"
- Direct use of `mcp__docker__docker` or `docker ps`
**Why**: Simple query, no processing needed

**Scenario**: "Read the config file at /path/to/config.yaml"
- Direct use of `Read` tool
**Why**: Single operation, immediate result

---

## Integration with PARC Pattern

During the **Assess** phase of PARC, consider agent selection:

1. **Check if task matches a built-in subagent** - code work → feature-dev:*
2. **Check if custom agent exists** - service issues → service-troubleshooter
3. **Check for existing skill** - /discover-docker, /check-health, etc.
4. **Fall back to direct tools** for simple operations

Add to your PARC checklist:
```
□ ASSESS:
  □ Is there a built-in subagent for this? (feature-dev, Explore, Plan)
  □ Is there a custom agent? (/agent list)
  □ Is there a skill/slash command? (/help)
  □ Or should I use direct tools?
```

---

## When to Create a New Custom Agent

Create a new custom agent when:

1. **Task repeats 3+ times** with similar pattern
2. **Benefits from memory** - learnings improve future runs
3. **Requires 5+ complex steps** - structured workflow helps
4. **Produces reusable output** - results files for reference
5. **Benefits from isolation** - deep focus without context pollution

Use the template:
```bash
cp .claude/agents/_template-agent.md .claude/agents/my-new-agent.md
```

---

## Combining Agents

Agents can work together:

1. **Sequential**: Use Explore → then feature-dev:code-architect → then custom agent for deployment
2. **Nested**: Custom agent can invoke `/agent` for sub-tasks
3. **Parallel**: Launch multiple agents for independent work

Example workflow:
```
1. Explore agent finds relevant code
2. feature-dev:code-explorer analyzes the patterns
3. You design with feature-dev:code-architect
4. /agent docker-deployer handles deployment
5. feature-dev:code-reviewer validates the result
```

---

## Related Documentation

- @.claude/context/systems/agent-system.md - Custom agent system details
- @.claude/agents/AGENT-ROADMAP.md - Agent planning and roadmap
- @.claude/context/patterns/prompt-design-review.md - PARC pattern integration
- @.claude/context/integrations/workflow-patterns.md - Workflow patterns
- @.claude/commands/agent.md - /agent slash command

---

**Maintained by**: Claude Code

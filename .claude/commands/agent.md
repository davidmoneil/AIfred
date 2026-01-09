---
argument-hint: [--model] <agent-name> [args]
description: Launch a specialized agent with optional model selection
allowed-tools: Read, Write, Task, Bash(date:*), mcp__memory__*
---

# Agent Launcher

Launch the **$ARGUMENTS** agent to work independently with its own context window.

## Jarvis Enhancements

- **Model Selection**: `/agent --sonnet code-analyzer` or `/agent --opus deep-research`
- **Memory Integration**: Dual-write to learnings.json AND Memory MCP
- **JICM Awareness**: Agents tracked for context checkpoint triggers

## Supported Models

| Flag | Model | Use Case |
|------|-------|----------|
| `--sonnet` | sonnet | Default — balanced speed/capability |
| `--opus` | opus | Complex research, architecture decisions |
| `--haiku` | haiku | Quick, simple tasks |

If no flag specified, defaults to `sonnet`.

## Execution Steps

### 1. Parse Arguments

Parse the command arguments:

```
/agent --sonnet deep-research "Docker networking best practices"
       ^^^^^^^^ ^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       model    agent-name    task arguments
```

- Look for model flag: `--sonnet`, `--opus`, or `--haiku`
- Next argument: agent name (e.g., "deep-research")
- Remaining arguments: passed to the agent

### 2. Load Agent Definition

- Read agent file: `.claude/agents/[agent-name].md`
- If file doesn't exist, list available agents from `.claude/agents/` and show usage
- Extract the agent prompt (everything after the `---` separator following the Metadata section)

### 3. Setup Session

Generate unique session identifier:
```bash
date +%Y-%m-%d_%H%M%S
```

Session ID format: `YYYY-MM-DD_[agent-name]_[timestamp]`

### 4. Initialize Memory (Dual System)

**File-based learnings** (learnings.json):
- Check if `.claude/agents/memory/[agent-name]/learnings.json` exists
- If not, create with initial structure:
```json
{
  "agent": "[agent-name]",
  "last_updated": "YYYY-MM-DD HH:MM:SS",
  "runs_completed": 0,
  "learnings": [],
  "patterns": []
}
```

**Memory MCP** (knowledge graph):
- Search for existing agent entity: `mcp__memory__search_nodes` with query "[agent-name]"
- If entity doesn't exist, will be created after agent run

### 5. Build Agent Context

Construct the full agent prompt by combining:

```
[Agent Prompt from the agent definition file]

---

## Current Session Context

**Session ID**: [session-id]
**Model**: [sonnet|opus|haiku]
**Arguments**: [args passed to agent]
**Date/Time**: [current timestamp]

### Your Task
[The specific task based on arguments]

### File Paths For This Session
- Session Log: .claude/agents/sessions/[session-id].md
- Results: .claude/agents/results/[agent-name]/YYYY-MM-DD_[descriptive-name].md
- Memory: .claude/agents/memory/[agent-name]/learnings.json

### Memory from Previous Runs
[Contents of learnings.json if it exists, or "No previous runs" if this is first time]

### Required Actions
1. Create session log at the specified path
2. Document your process with status updates
3. Create results file with your findings
4. Update memory file with new learnings
5. Return a concise summary (2-3 sentences) with links to results and session log

Begin your work now.
```

### 6. Launch Agent

Use the Task tool:
- **subagent_type**: "general-purpose"
- **model**: [parsed from --flag or default "sonnet"]
- **description**: "[agent-name]: [brief task description]"
- **prompt**: [the constructed agent context from step 5]

### 7. Handle Response

When the agent completes:

1. **Display Summary**: Show the agent's summary

2. **Update Dual Memory**:
   - Update learnings.json with new learnings
   - Create/update Memory MCP entity for the agent:
     ```
     mcp__memory__add_observations({
       observations: [{
         entityName: "Agent_[agent-name]",
         contents: ["Run [session-id]: [key learning summary]"]
       }]
     })
     ```

3. **Provide Links**:
   - Session log
   - Results file
   - Memory file (if updated)

## Example Usage

```bash
# Default model (sonnet)
/agent deep-research "Docker networking best practices"

# Specify opus for complex research
/agent --opus deep-research "comprehensive analysis of microservices patterns"

# Use haiku for quick tasks
/agent --haiku code-analyzer src/utils

# List available agents
/agent
```

## Available Agents

List agents by reading `.claude/agents/` directory (exclude files starting with `_` and directories).

**Current Jarvis Agents**:
- `deep-research` — Multi-source technical research
- `docker-deployer` — Docker deployment with validation
- `service-troubleshooter` — Systematic issue diagnosis
- `memory-bank-synchronizer` — Doc sync with code changes
- `code-analyzer` — Pre-implementation codebase analysis
- `code-implementer` — Code writing with git workflow
- `code-tester` — Testing + Playwright automation

For each agent, show:
- Agent name
- Purpose (from metadata)
- Suggested model (if specified in agent metadata)
- Example usage

## Error Handling

- **Invalid model flag**: Show valid options (--sonnet, --opus, --haiku)
- **Agent not found**: List available agents and show usage
- **No arguments**: Show available agents and usage examples
- **Memory file corrupted**: Create new memory file, note in session log
- **Agent fails**: Capture error in session log, return error summary

## Memory Architecture

Jarvis uses TWO memory systems (they are NOT redundant):

| System | Purpose | Storage |
|--------|---------|---------|
| **learnings.json** | Per-agent learning accumulation | `.claude/agents/memory/[agent]/` |
| **Memory MCP** | Cross-agent knowledge graph | `~/.claude/memory.json` |

**Integration Pattern**:
1. Agent completes work → updates learnings.json
2. Key learnings → added to Memory MCP as observations
3. Memory MCP entities → available across all agents and sessions
4. learnings.json → specific to individual agent improvement

## Notes

- Each agent runs independently with its own context window
- Agents can call other agents (they'll use this same /agent command)
- Model selection allows cost/capability optimization per task
- Session logs are kept for tracking and debugging
- Memory accumulates over time to improve agent performance
- All file paths are relative to the project root
- SubagentStop hook will trigger JICM checkpoint if context threshold exceeded

---

*Jarvis Agent Launcher v1.0*
*Adapted from AIfred baseline 2ea4e8b with model selection + dual memory*

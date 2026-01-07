---
argument-hint: <agent-name> [args]
description: Launch a specialized agent to work independently
allowed-tools: Read, Write, Task, Bash(date:*)
---

Launch the **$ARGUMENTS** agent to work independently with its own context window.

## Execution Steps

### 1. Parse Arguments
- First argument: agent name (e.g., "deep-research")
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

### 4. Initialize Memory (if agent has Memory Enabled: Yes)
- Check if `.claude/agents/memory/[agent-name]/learnings.json` exists
- If not, create with initial structure:
```json
{
  "last_updated": "YYYY-MM-DD HH:MM:SS",
  "runs_completed": 0,
  "learnings": [],
  "patterns": []
}
```

### 5. Build Agent Context
Construct the full agent prompt by combining:

```
[Agent Prompt from the agent definition file]

---

## Current Session Context

**Session ID**: [session-id]
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
- subagent_type: "general-purpose"
- model: "sonnet" (use "opus" for complex research, "haiku" for simple tasks)
- description: "[agent-name]: [brief task description]"
- prompt: [the constructed agent context from step 5]

### 7. Handle Response
When the agent completes:
- Display the agent's summary
- Provide links to:
  - Session log
  - Results file
  - Memory file (if updated)

## Example Usage

```bash
# Launch deep research agent
/agent deep-research "Docker networking best practices"

# Launch code analyzer
/agent code-analyzer my-project

# List available agents
/agent
```

## Available Agents

List agents by reading `.claude/agents/` directory (exclude files starting with `_` and directories).

For each agent, show:
- Agent name
- Purpose (from metadata)
- Example usage

## Error Handling

- **Agent not found**: List available agents and show usage
- **No arguments**: Show available agents and usage examples
- **Memory file corrupted**: Create new memory file, note in session log
- **Agent fails**: Capture error in session log, return error summary

## Notes

- Each agent runs independently with its own context window
- Agents can call other agents (they'll use this same /agent command)
- Session logs are kept for 90 days (cleanup via cron - see docs)
- Memory accumulates over time to improve agent performance
- All file paths are relative to the project root

# Agent: [Agent Name]

## Metadata
- **Purpose**: [Brief description]
- **Can Call**: [Other agents, or "none"]
- **Memory Enabled**: Yes/No
- **Session Logging**: Yes
- **Created**: [YYYY-MM-DD]

## Status Messages
- "Starting [task]..."
- "Gathering [resources]..."
- "Processing [data]..."
- "Finalizing [output]..."

## Expected Output
- **Results Location**: `.claude/agents/results/[agent-name]/`
- **Session Logs**: `.claude/agents/sessions/`
- **Summary Format**: Brief overview with key findings

## Usage
```bash
# Via Task tool
subagent_type: [agent-name]
prompt: "Your task description"
```

---

## Agent Prompt

You are a specialized agent for [specific purpose]. You work independently with your own context window.

### Your Role
[Detailed description of role and responsibilities]

### Your Capabilities
- [Capability 1]
- [Capability 2]
- [Capability 3]

### Your Workflow
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Memory System
Read from `.claude/agents/memory/[agent-name]/learnings.json` at start.
Update learnings at end of session.

Memory schema:
```json
{
  "last_updated": "YYYY-MM-DD HH:MM:SS",
  "runs_completed": 0,
  "learnings": [
    {
      "date": "YYYY-MM-DD",
      "insight": "What was learned",
      "context": "What led to this"
    }
  ],
  "patterns": [
    {
      "pattern": "Description",
      "frequency": "How often",
      "action": "What to do"
    }
  ]
}
```

### Output Requirements

1. **Session Log** - Full transcript of work
2. **Results File** - Polished output with findings
3. **Summary** - 2-3 sentence overview for caller
4. **Memory Update** - New learnings captured

### Guidelines
- Work independently and autonomously
- Use all available tools
- Be thorough but efficient
- Document your process
- Update status messages as you work

### Success Criteria
[What constitutes successful completion]

---

## Notes
[Additional context, limitations, considerations]

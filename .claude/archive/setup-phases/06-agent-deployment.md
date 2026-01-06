# Phase 6: Agent Deployment

**Purpose**: Deploy starter agents based on user preferences.

---

## Agent Selection Interview

Present available agents to the user and let them choose which to install.

### Core Agents (Recommended)

| Agent | Description | Default |
|-------|-------------|---------|
| `docker-deployer` | Deploy and configure Docker services safely | ✅ Install |
| `service-troubleshooter` | Diagnose infrastructure issues with learned patterns | ✅ Install |
| `deep-research` | In-depth investigation with web research and citations | ✅ Install |

### Interview Question

"Which agents would you like to install?"

**Options**:
- **Install all core agents** (Recommended) - All 3 agents above
- **Select specific agents** - Choose from the list
- **Skip agent deployment** - Can install later with `/install-agent`

**If "Select specific agents"**:
Present checkboxes for each agent with descriptions:
- [ ] docker-deployer - For Docker service deployment
- [ ] service-troubleshooter - For diagnosing infrastructure issues
- [ ] deep-research - For in-depth web research

**Default**: Install all core agents

### Follow-up

"Additional agents can be installed anytime using `/install-agent <name>`.
Would you like to see available optional agents?"

If yes, mention:
- Custom agents can be created from `.claude/agents/_template-agent.md`
- Agent marketplace/registry planned for future

---

## Deployment Process

For each selected agent:

1. Verify agent definition exists in `.claude/agents/`
2. Initialize agent memory directory
3. Create results directory
4. Log deployment

---

## Core Agents

### 1. docker-deployer

**Purpose**: Safely deploy and configure Docker services

Deploy from `.claude/agents/docker-deployer.md`

Initialize memory:
```bash
mkdir -p .claude/agents/memory/docker-deployer
echo '{"last_updated": null, "runs_completed": 0, "learnings": [], "patterns": []}' > .claude/agents/memory/docker-deployer/learnings.json
```

### 2. service-troubleshooter

**Purpose**: Diagnose infrastructure issues with learned patterns

Deploy from `.claude/agents/service-troubleshooter.md`

Initialize memory with common patterns:
```json
{
  "last_updated": "[date]",
  "runs_completed": 0,
  "learnings": [],
  "patterns": [
    {
      "pattern": "Container restart loop",
      "symptoms": ["Container status: restarting", "Exit code non-zero"],
      "common_causes": ["Bad config", "Missing volume", "Port conflict"],
      "diagnostic_steps": ["Check logs", "Inspect container", "Verify volumes"]
    },
    {
      "pattern": "Service unreachable",
      "symptoms": ["Connection refused", "Timeout"],
      "common_causes": ["Container not running", "Wrong port", "Firewall"],
      "diagnostic_steps": ["Check container status", "Verify port mapping", "Test connectivity"]
    }
  ]
}
```

### 3. deep-research

**Purpose**: In-depth investigation with citations

Deploy from `.claude/agents/deep-research.md`

Initialize memory:
```bash
mkdir -p .claude/agents/memory/deep-research
echo '{"last_updated": null, "runs_completed": 0, "learnings": [], "research_history": []}' > .claude/agents/memory/deep-research/learnings.json
```

---

## Agent Directory Structure

Ensure structure exists:

```
.claude/agents/
├── _template-agent.md
├── docker-deployer.md
├── service-troubleshooter.md
├── deep-research.md
├── memory/
│   ├── docker-deployer/
│   │   └── learnings.json
│   ├── service-troubleshooter/
│   │   └── learnings.json
│   └── deep-research/
│       └── learnings.json
├── sessions/
│   └── .gitkeep
└── results/
    ├── docker-deployer/
    ├── service-troubleshooter/
    └── deep-research/
```

---

## Agent Template

Ensure `.claude/agents/_template-agent.md` is available for creating new agents.

---

## Validation

- [ ] Required agents deployed
- [ ] Agent memory initialized
- [ ] Results directories created
- [ ] Template available
- [ ] Test agent invocation works

Test command:
```
/agent service-troubleshooter test
```

---

*Phase 6 of 7 - Agent Deployment*

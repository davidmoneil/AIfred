# Phase 6: Agent Deployment

**Purpose**: Deploy starter agents based on user focus areas.

---

## Agent Selection

Based on Phase 2 interview:

| Focus Area | Agents to Deploy |
|------------|------------------|
| Home Lab / Infrastructure | docker-deployer, service-troubleshooter |
| Development | (code agents if requested) |
| All | docker-deployer, service-troubleshooter, deep-research |

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

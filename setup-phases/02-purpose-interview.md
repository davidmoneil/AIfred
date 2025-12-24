# Phase 2: Purpose Interview

**Purpose**: Understand user goals through outcome-focused questions.

---

## Interview Questions

Ask these questions to understand the user's needs. Focus on **outcomes**, not technical specifics.

### Question 1: Primary Purpose

"What will you primarily use AIfred for?"

**Options** (multi-select):
- **Home Lab Management**: Docker services, networking, servers
- **Development Projects**: Writing code, managing git repos
- **System Administration**: Monitoring, backups, maintenance
- **Learning & Documentation**: Building a knowledge base
- **All of the above**

### Question 2: Automation Level

"How much automation do you want?"

**Options**:
- **Full Automation**: Run everything without asking. I trust the system.
- **Guided**: Ask me before major changes, automate routine tasks.
- **Manual Control**: Ask me before most actions. I want to approve things.

### Question 3: Existing Infrastructure

"What existing infrastructure should AIfred know about?"

**Options** (multi-select):
- **Docker services on this machine**
- **Other servers I can SSH to**
- **NAS/network storage**
- **Nothing yet - this is a fresh start**

### Question 4: Memory & Persistence

"Would you like AIfred to remember things between sessions?"

**Explanation**: "Memory MCP stores decisions, lessons learned, and relationships. It requires Docker."

**Options**:
- **Yes, enable persistent memory** (Recommended if Docker available)
- **No, I'll manage context files manually**

### Question 5: Session Management

"How should sessions be managed?"

**Options**:
- **Automated**: End-session runs automatically, commits changes
- **Prompted**: Remind me to run /end-session with a checklist
- **Manual**: I'll handle it myself

### Question 6: GitHub Integration

"Would you like AIfred changes tracked in GitHub?"

**Options**:
- **Yes, set up remote**: Push changes to my GitHub repo
- **Local only**: Just use local git, I'll push manually
- **No git**: Don't track changes (not recommended)

---

## Derived Configuration

Based on answers, determine:

| Setting | Source |
|---------|--------|
| `focus_areas` | Question 1 |
| `automation_level` | Question 2 (full/guided/manual) |
| `enable_discovery` | Question 3 |
| `enable_memory_mcp` | Question 4 |
| `session_mode` | Question 5 |
| `github_enabled` | Question 6 |

---

## Configuration Summary

Create `.claude/context/user-preferences.md`:

```markdown
# User Preferences

Configured during AIfred setup on [date].

## Focus Areas
- [list from Q1]

## Automation Level
[full/guided/manual]

## Features Enabled
- Docker Discovery: [yes/no]
- Memory MCP: [yes/no]
- Session Automation: [level]
- GitHub Sync: [yes/no]

## Notes
[Any additional context from interview]
```

---

## Next Phase Preparation

Based on answers, prepare for Phase 3:

- If Docker discovery: Will scan containers in Phase 3
- If Memory MCP: Will deploy in Phase 4
- If GitHub: Will configure remote in Phase 7

---

*Phase 2 of 7 - Purpose Interview*

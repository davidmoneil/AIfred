# Phase 2: Purpose Interview

**Purpose**: Understand user goals through outcome-focused questions, then select environment profile layers.

---

## Step 1: Profile Layer Selection

"What will you use AIfred for?"

**Options** (multi-select):
- **Home Lab Management**: Docker services, NAS, monitoring, networking
  → Adds `homelab` profile layer
- **Development Projects**: Writing code, managing git repos, CI/CD
  → Adds `development` profile layer
- **Production / Operations**: Deployment gates, security hardening, strict audit
  → Adds `production` profile layer

*The `general` profile is always active (core hooks, security, audit logging).*

**Store**: Selected layers → `.claude/config/active-profile.yaml`

---

## Step 2: Profile-Specific Questions

After layer selection, load `setup_questions` from each selected profile YAML and ask them dynamically.

### How Dynamic Questions Work

1. Load profile YAML files for selected layers
2. Collect all `setup_questions` from each profile (in layer order)
3. Skip duplicate question IDs
4. Evaluate `condition` fields (skip questions whose conditions aren't met)
5. Ask questions, storing answers in the config
6. Process `follow_ups` for conditional sub-questions

### Question Types

| Type | UI | Example |
|------|-----|---------|
| `text` | Free text input | "Which services are critical?" |
| `choice` | Single selection | "What monitoring stack?" |
| `multi-choice` | Multi selection | "Which MCP servers to enable?" |
| `boolean` | Yes/No | "Do you have a NAS?" |
| `path` | Directory path | "Where do projects live?" |

---

## Step 3: Common Questions (Always Asked)

These questions are always asked regardless of profile:

### Automation Level

"How much automation do you want?"

**Options**:
- **Full Automation**: Run everything without asking. I trust the system.
- **Guided**: Ask me before major changes, automate routine tasks.
- **Manual Control**: Ask me before most actions. I want to approve things.

### Memory & Persistence

"Would you like AIfred to remember things between sessions?"

**Explanation**: "Memory MCP stores decisions, lessons learned, and relationships. It requires Docker."

**Options**:
- **Yes, enable persistent memory** (Recommended if Docker available)
- **No, I'll manage context files manually**

### Session Management

"How should sessions be managed?"

**Options**:
- **Automated**: End-session runs automatically, commits changes
- **Prompted**: Remind me to run /end-session with a checklist
- **Manual**: I'll handle it myself

### GitHub Integration

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
| `profile_layers` | Step 1 (layer selection) |
| `automation_level` | Step 3 (full/guided/manual) |
| `enable_memory_mcp` | Step 3 |
| `session_mode` | Step 3 |
| `github_enabled` | Step 3 |
| Profile-specific settings | Step 2 (dynamic questions) |

---

## Output

### Write Active Profile

Create `.claude/config/active-profile.yaml`:

```yaml
layers:
  - general
  - homelab        # if selected
  - development    # if selected
  - production     # if selected

config:
  automation_level: guided
  memory_mcp: true
  session_mode: prompted
  github: true
  # Profile-specific answers stored by stores_as paths:
  docker:
    compose_dir: ~/docker
    critical_services: "portainer,caddy"
  development:
    projects_root: ~/Code
    parallel_dev_enabled: true
```

### Create User Preferences

Create `.claude/context/user-preferences.md`:

```markdown
# User Preferences

Configured during AIfred setup on [date].

## Profile Layers
- [list of active layers]

## Automation Level
[full/guided/manual]

## Features Enabled
- Memory MCP: [yes/no]
- Session Automation: [level]
- GitHub Sync: [yes/no]

## Notes
[Any additional context from interview]
```

---

## Next Phase Preparation

Based on answers, prepare for Phase 3:

- Profile layers determine which hooks get registered (Phase 5)
- If Docker discovery: Will scan containers in Phase 3
- If Memory MCP: Will deploy in Phase 4
- If GitHub: Will configure remote in Phase 7

---

*Phase 2 of 7 - Purpose Interview*

# Marvin Chief of Staff Pattern Analysis

**Date**: 2026-02-05  
**Topic**: Design philosophy for consistent AI assistant behavior  
**Repository**: https://github.com/SterlingChin/marvin-template

---

## Key Insights

### Core Design Principle: Workspace Separation

Marvin's reliability comes from **architectural separation of template from user data**:

- **Template** (`~/Downloads/marvin-template/`): Update source, never contains user data
- **Workspace** (`~/marvin/`): User's personal state, never overwritten during updates
- **Pointer** (`.marvin-source`): Links workspace to template for `/sync` command

**Result**: Users can `git pull` new features without destroying personal state.

### Consistency Mechanisms

1. **File-Based Commands** (not in-context prompts) — prevents drift
2. **YAML Frontmatter Skills** — behavior contracts with metadata
3. **Date-Based Session Files** (`sessions/YYYY-MM-DD.md`) — chronological history
4. **Structured State Files** — mandatory schemas for consistency
5. **Setup Script Standardization** — all integrations follow same pattern
6. **Fixed Output Templates** — users know what to expect

### Session Lifecycle Protocol

**Every session follows same pattern**:

`/start`:
1. `date +%Y-%m-%d` → TODAY
2. Read CLAUDE.md (profile)
3. Read state/current.md (priorities)
4. Read state/goals.md (goals)
5. Read sessions/{TODAY}.md or yesterday's
6. Present briefing (fixed format)

`/end`:
1. Extract topics, decisions, open threads, actions
2. Append to sessions/{TODAY}.md
3. Update state/current.md
4. Confirm

`/update`:
1. Brief scan (no full summary)
2. Append to sessions/{TODAY}.md
3. Update state/current.md ONLY if changed
4. One-line confirmation

### Skill System

Skills use **YAML frontmatter** to declare behavior:

```yaml
---
name: content-shipped
description: Log shipped content when user mentions completion
metadata:
  marvin-category: content
  user-invocable: false
  slash-command: null
  proactive: true
---
```

**Metadata enables**:
- Proactive detection (trigger phrases)
- User-invocable commands (slash commands)
- Behavior validation (introspection)

### Integration Patterns

All integrations:
1. Use MCP servers (`claude mcp add`)
2. Follow standardized setup script structure
3. Include mandatory "Danger Zone" risk documentation
4. Provide scope selection (user vs. project)

### State Management

**Structured files**:
- `state/current.md`: Priorities, open threads, recent context
- `state/goals.md`: Annual goals with tracking table
- `sessions/YYYY-MM-DD.md`: Daily session logs
- `content/log.md`: Shipped work tracking

**Migration strategy** (`migrate.sh`):
1. Copy template structure
2. Overlay user data (preserves customizations)
3. Create pointer file (`.marvin-source`)

---

## Applications to Jarvis

### Immediate Wins

1. **Create `.jarvis-source` pointer** to AIfred baseline
2. **Migrate to dated session files** (`sessions/YYYY-MM-DD.md`)
3. **Add YAML frontmatter** to all skills
4. **Move commands to files** (`.claude/commands/*.md`)
5. **Standardize setup scripts** for hooks/integrations

### Structural Changes

1. **Workspace Separation**:
   - `/Jarvis/jarvis-template/` (AIfred baseline, read-only)
   - `/Jarvis/workspace/` (Aircannon's state)
   - `.jarvis-source` pointer

2. **State Schema**:
   ```markdown
   # current-priorities.md
   
   Last updated: YYYY-MM-DDTHH:MM:SSZ
   
   ## Active Priorities
   1. [Priority with context]
   
   ## Open Threads
   - [Thread description]
   
   ## Recent Context
   - [Recent work]
   ```

3. **Command Files**:
   - `.claude/commands/end-session.md`
   - `.claude/commands/checkpoint.md`
   - `.claude/commands/tooling-health.md`

### Design Principles

1. **File-based > In-context** (prevents drift)
2. **Explicit > Implicit** (bash commands, not "get date")
3. **Structured > Prose** (schemas, not paragraphs)
4. **Template-first, overlay-user** (safe updates)
5. **Validate early** (setup-time, not runtime)
6. **Document risk** (mandatory danger zones)

---

## Related Research

- **Progressive Disclosure**: Marvin loads context incrementally (CLAUDE.md, then state, then sessions)
- **Self-Modification**: `skill-creator` skill enables conversational capability extension
- **Proactive Detection**: Skills with `proactive: true` watch conversation for triggers
- **Safe Updates**: `/sync` only adds new, never overwrites user customizations

---

## Full Report

See: `.claude/reports/research/marvin-design-philosophy-2026-02-05.md`

---

*Researched by: Jarvis Deep Research Agent*  
*Saved: 2026-02-05*

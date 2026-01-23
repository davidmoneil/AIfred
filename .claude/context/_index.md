# Context Index — Map of Nous

Central navigation for the Jarvis knowledge base (the Nous layer).

**Version**: 3.0.0 (Archon Architecture)
**Philosophy**: Minimal, curated, always-relevant context

---

## The Archon Architecture

Jarvis is an **Archon** — an autonomous entity within Project Aion. The Archon Architecture defines three layers:

| Layer | Greek | Location | Purpose |
|-------|-------|----------|---------|
| **Nous** | νοῦς (intellect) | `.claude/context/` | Knowledge, patterns, state (you are here) |
| **Pneuma** | πνεῦμα (vital force) | `.claude/` | Capabilities, persona, tools |
| **Soma** | σῶμα (body) | `/Jarvis/` | Infrastructure, interfaces |

This index maps **Nous** — operational knowledge that guides behavior.

### Neuro & Psyche

- **Neuro** (νεύρο) — The navigation substrate; cross-references and links connecting layers
- **Psyche** (ψυχή) — Documented maps of the Neuro; topology documentation

See `psyche/_index.md` for the complete Archon topology map.

---

## Quick Access

| Need | Location |
|------|----------|
| Current work status | [session-state.md](session-state.md) |
| Active tasks | [current-priorities.md](current-priorities.md) |
| All paths | @paths-registry.yaml |
| Pattern selection | [patterns/_index.md](patterns/_index.md) |

---

## Nous Structure

### Session State (Top Level)

Core files for session continuity:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `session-state.md` | Current work status, blockers | Every session |
| `current-priorities.md` | Active tasks and priorities | When work completes |
| `configuration-summary.md` | Current setup state | After config changes |

### Patterns (Behavioral Rules)

How Jarvis behaves — 39 patterns organized by category.

**Index**: [patterns/_index.md](patterns/_index.md)

**Mandatory Patterns** (apply ALWAYS):
- `wiggum-loop-pattern.md` — Multi-pass verification (DEFAULT)
- `startup-protocol.md` — Session start sequence
- `jicm-pattern.md` — Context management
- `selection-intelligence-guide.md` — Tool/agent selection

### Standards (Conventions)

Project-wide rules for consistency:

| Standard | Purpose |
|----------|---------|
| `severity-status-system.md` | `[X] CRITICAL` / `[!] HIGH` / etc. |
| `model-selection.md` | Opus vs Sonnet vs Haiku |
| `readme-standard.md` | README requirements |

### Workflows (Procedures)

Step-by-step guides for recurring tasks:

| Workflow | Purpose |
|----------|---------|
| `session-exit.md` | Clean session ending |

### Integrations (Tool Selection)

How to choose and use tools:

| File | Purpose |
|------|---------|
| `capability-matrix.md` | Task → tool selection |
| `overlap-analysis.md` | Tool conflict resolution |
| `mcp-installation.md` | MCP setup guide |
| `memory-usage.md` | Memory MCP guidelines |
| `skills-selection-guide.md` | Skill selection |

### Components (Autonomic Specs)

AC-01 through AC-09 component specifications:

```
components/
├── AC-01-self-launch.md      # Session startup
├── AC-02-wiggum-loop.md      # Multi-pass verification
├── AC-04-jicm.md             # Context management
├── AC-05-self-reflection.md  # Session learnings
├── AC-06-self-evolution.md   # Capability growth
├── AC-07-rd-cycles.md        # Research & development
├── AC-08-maintenance.md      # Health checks
└── AC-09-session-completion.md # Session exit
```

### Reference (On-Demand)

Detailed documentation too verbose for always-on context:

```
reference/
├── workflow-patterns.md     # PARC, DDLA, COSA
├── project-management.md    # Auto-detection, registration
└── commands-quick-ref.md    # All commands by category
```

### Archive

Historical session states and completed work.

---

## Pneuma Layer (Parent Directory)

The Pneuma layer (`.claude/`) contains capabilities:

| Directory | Purpose |
|-----------|---------|
| `agents/` | Custom agent definitions |
| `commands/` | Slash command specifications |
| `hooks/` | Event-triggered behaviors |
| `skills/` | Skill implementations |
| `scripts/` | Utility scripts |
| `config/` | Configuration files |
| `state/` | Runtime state files |
| `logs/` | Operational logs |

**Identity**: `.claude/jarvis-identity.md` — Jarvis persona specification

---

## Project Aion (Evolution Layer)

Evolution documentation lives in `projects/project-aion/`:

```
projects/project-aion/
├── roadmap.md                    # Master development roadmap
├── versioning-policy.md          # Version bumping rules
├── designs/                      # Architecture documents
│   ├── current/                  # Active designs
│   └── archive/                  # Historical designs
├── plans/                        # Implementation plans
│   ├── current/                  # Active plans
│   └── archive/                  # Completed plans
├── evolution/                    # Self-improvement tracking
│   ├── aifred-integration/       # AIfred baseline work
│   └── self-improvement/         # Autonomic improvements
├── ideas/                        # Brainstorms
├── reports/                      # Analysis reports
└── progress/                     # Session/milestone progress
```

**Design Principle**:
- **BEHAVIOR** (how Jarvis operates) → `.claude/context/`
- **EVOLUTION** (how Jarvis improves) → `projects/project-aion/`

---

## File Lifecycle

```
Discovery → Documentation → Context → Automation → Archive
```

1. **Discovery**: New findings go in context or ideas
2. **Documentation**: Clean docs go in appropriate subdirectory
3. **Context**: Stable, frequently-used info becomes context files
4. **Automation**: Proven processes become slash commands
5. **Archive**: Outdated/one-off items move to archive

---

## Navigation Tips

**When implementing tasks**:
1. Check `patterns/_index.md` for applicable patterns
2. Apply mandatory patterns (Wiggum Loop is DEFAULT)
3. Store decisions in Memory MCP
4. Update relevant context files

**When looking for information**:
1. Check this index first
2. Use `@` imports to load specific files
3. If not documented, help create it

---

## Maintenance

**Create a context file when**:
- Referenced 3+ times
- Critical for a system
- Contains paths/commands used regularly

**Update files when**:
- New information discovered
- Configuration changed
- Problem solved worth documenting

**Refactor when**:
- File exceeds 300 lines (split it)
- Multiple files duplicate info (consolidate)

---

## Recent Updates

**2026-01-22**: Archon Architecture (v3.0.0)
- Living Soul → Archon Architecture (Greek terminology)
- Mind/Spirit/Body → Nous/Pneuma/Soma
- Introduced Neuro (navigation substrate) and Psyche (topology maps)
- Aion = Project, Archon = Entity distinction established

**2026-01-22**: Organization Architecture (v2.0.0)
- Organization Architecture Phases 1-6 complete
- Path references updated (current-priorities.md elevated)
- patterns/_index.md comprehensive rewrite (39 patterns)
- CLAUDE.md pattern selection matrix added
- Three-layer architecture documented

**2026-01-16**: PR-12 Autonomic Components
- AC-01 through AC-09 specifications
- Wiggum Loop (AC-02) as default behavior
- Session lifecycle automation

---

*Context Index v3.0.0 — Map of Nous (Archon Architecture)*
*Last Updated: 2026-01-22*

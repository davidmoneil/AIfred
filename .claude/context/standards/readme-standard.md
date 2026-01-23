# README Standard

**Version**: 2.0.0
**Created**: 2026-01-22
**Updated**: 2026-01-22 (Archon Architecture terminology)
**Status**: Active

---

## Purpose

Every directory in Jarvis' structure MUST have a README.md that explains:
1. The directory's purpose
2. What belongs there
3. What does NOT belong there
4. Lifecycle/workflow information (if applicable)

---

## Mandatory Behavior

### When Entering a Directory

**Jarvis MUST check the README.md** when:
- First accessing a directory in a session
- Creating new files in a directory
- Moving files to a directory
- Uncertain about where something belongs

### When Creating a Directory

**Jarvis MUST create a README.md** that includes:
- Purpose statement (1-2 sentences)
- What belongs here
- What does NOT belong here
- Lifecycle notes (if applicable)

---

## README Template

```markdown
# [Directory Name]

**Purpose**: [One-line description of what this directory contains]

**Layer**: [Nous | Pneuma | Soma] (within Archon structure)

---

## What Belongs Here

- [Item type 1]
- [Item type 2]

## What Does NOT Belong Here

- [Item type] → [correct location]
- [Item type] → [correct location]

## Lifecycle (if applicable)

1. [Step 1]
2. [Step 2]

---

*[Context note — e.g., "Jarvis — Nous Layer"]*
```

---

## Directory Hierarchy

READMEs should reference the organizational hierarchy when relevant:

### Nous Layer (`/.claude/context/`) — Knowledge & Patterns
```
Standards (MUST follow)
    ↓
Patterns (SHOULD follow)
    ↓
Workflows (Large task procedures)
    ↓
Designs (Architecture philosophy)
    ↓
Plans (Session-level work)
    ↓
Lessons (Memory)
```

### Pneuma Layer (`/.claude/`) — Capabilities & Tools
```
Identity (CLAUDE.md, jarvis-identity.md)
    ↓
Capabilities (commands, hooks, skills, agents)
    ↓
State (state, logs, metrics, reports)
    ↓
Configuration (config, secrets)
```

### Soma Layer (`/Jarvis/`) — Infrastructure & Interfaces
```
Infrastructure (docker, scripts, external-sources)
    ↓
Interface (docs)
    ↓
Projects (development workspaces)
```

---

## Enforcement

This standard is enforced by:
1. **Session start**: Check key READMEs as part of context loading
2. **File operations**: Consult README before creating/moving files
3. **Self-review**: Verify READMEs exist and are current during maintenance cycles

---

*Jarvis Standards — Organization*

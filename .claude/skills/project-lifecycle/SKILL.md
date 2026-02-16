---
name: project-lifecycle
version: 1.0.0
description: End-to-end project management from creation through consolidation and archival
category: workflow
tags: [projects, lifecycle, creation, registration, consolidation]
created: 2026-01-16
context: fork
agent: general-purpose
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(mkdir:*)
  - mcp__filesystem__write_file
  - mcp__filesystem__create_directory
---

# Project Lifecycle Skill

Complete project management workflow from creation through consolidation and archival.

---

## Overview

This skill consolidates all project lifecycle operations:
- **Creation**: New code projects in ~/Code or internal projects in .claude/projects
- **Registration**: Register existing projects with AIfred tracking
- **Consolidation**: Sync knowledge, update docs, create commits
- **Management**: Track priorities, update context files

**Value**: Unified approach to project management with consistent patterns and documentation.

---

## Quick Actions

| Need | Action | Reference |
|------|--------|---------|
| Create new code project | `/new-code-project <name>` | @.claude/commands/new-code-project.md |
| Register existing project | `/register-project <path-or-url>` | @.claude/commands/register-project.md |
| Create internal project | `/create-project <name>` | @.claude/commands/create-project.md |
| Consolidate project knowledge | `/consolidate-project <name>` | @.claude/commands/consolidate-project.md |

---

## Project Lifecycle Workflow

```
PROJECT LIFECYCLE
=================

CREATE (new projects)
  /new-code-project <name>
    - Creates in ~/Code/<name>
    - Initializes git, README, .claude/CLAUDE.md
    - Registers in paths-registry.yaml
    - Creates context file at .claude/context/projects/<name>.md

  /create-project <name>
    - Creates internal project in .claude/projects/<name>
    - For non-code projects (writing, research, planning)
    - Creates project structure with config.yaml

REGISTER (existing projects)
  /register-project <path-or-url>
    - Clones GitHub URL to ~/Code/ if needed
    - Auto-detects language/type
    - Adds to paths-registry.yaml
    - Creates context file

CONSOLIDATE (ongoing maintenance)
  /consolidate-project <name>
    - Updates context file with current state
    - Syncs documentation with code
    - Creates git commit with changes
    - Options: --infrastructure, --analyze, --all

ARCHIVE (completed projects)
  - Move context to .claude/context/archive/
  - Update paths-registry.yaml status
  - Optional: Remove from ~/Code/
```

---

## Project Locations

Understanding where projects live:

| Project Type | Location | Registration |
|--------------|----------|--------------|
| Code projects | `~/Code/<project>/` | `paths-registry.yaml` → `coding.projects` |
| Internal projects | `.claude/projects/<project>/` | Direct in AIfred |
| Context/notes | `.claude/context/projects/<project>.md` | Always in AIfred |
| External sources | `external-sources/<category>/` | Symlinks to external data |

---

## Context File Template

When creating project context files, use this structure:

```markdown
# Project: <name>

**Type**: web-app | api | cli | library | docker | internal
**Language**: typescript | python | go | rust | N/A
**Location**: ~/Code/<name> or .claude/projects/<name>
**Status**: active | maintenance | archived
**Created**: YYYY-MM-DD

## Overview

Brief description of project purpose.

## Key Files

- `src/` - Main source code
- `README.md` - Project documentation

## Current State

What's working, what's in progress.

## Integration Points

How this connects to AIfred infrastructure.
```

---

## Registration Patterns

### GitHub URL Detection

When user mentions a GitHub URL:
1. Check if already registered in `paths-registry.yaml`
2. If not, clone to `~/Code/<repo-name>`
3. Auto-detect language from file extensions
4. Add to registry under `coding.projects`
5. Create context file

### Existing Local Project

When registering an existing local project:
1. Verify path exists
2. Detect project type and language
3. Add to `paths-registry.yaml`
4. Create context file
5. Optionally initialize `.claude/CLAUDE.md` in project

---

## Integration Points

### With Session Management
- New projects can be noted in session-state.md
- Project work tracked via current-priorities.md

### With Orchestration
- Complex project setup may trigger orchestration
- Use `/orchestration:plan "setup [project]"` for multi-phase setup

### With Memory MCP
- Store project metadata as Memory entities
- Track project relationships and dependencies

### With paths-registry.yaml
- Source of truth for all project locations
- Check before assuming any path

---

## Common Workflows

### Starting a New Feature Project

```
1. /new-code-project my-feature --type api --lang typescript
2. Review generated structure in ~/Code/my-feature
3. Update context file with specific requirements
4. Begin development
```

### Onboarding Existing Project

```
1. /register-project https://github.com/user/repo
2. Review auto-detected settings
3. Update context file with domain knowledge
4. Add any custom CLAUDE.md to the project
```

### Project Knowledge Sync

```
1. /consolidate-project my-project
2. Review documentation updates
3. Commit changes
4. Update session-state.md if needed
```

---

## Troubleshooting

### Project not appearing in registry?
- Check `paths-registry.yaml` directly
- Verify path exists: `ls ~/Code/<project>`
- Re-run `/register-project <path>`

### Context file out of date?
- Run `/consolidate-project <name>`
- Review changes before committing
- Update manually if consolidation misses details

### Git clone failing?
- Check SSH key: `ssh -T git@github.com`
- Verify URL format
- Check network connectivity

---

## Related Documentation

### Commands
- @.claude/commands/new-code-project.md - New code project creation
- @.claude/commands/register-project.md - Project registration
- @.claude/commands/create-project.md - Internal project creation
- @.claude/commands/consolidate-project.md - Project consolidation

### Context Files
- @paths-registry.yaml - Project registration source of truth
- @.claude/context/projects/ - All project context files
- @.claude/templates/project-template/ - Project template structure

### Patterns
- @.claude/context/patterns/memory-storage-pattern.md - When to store in Memory
- @.claude/context/standards/documentation-location.md - Where to document

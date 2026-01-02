# /create-project

Create a new project with proper structure and register it with AIfred.

## Usage

```
/create-project <name> [--type <type>] [--language <lang>]
```

**Examples**:
```
/create-project my-new-api
/create-project dashboard --type web-app --language typescript
/create-project backup-scripts --type cli --language python
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Project name (will be normalized to lowercase-with-dashes) |
| `--type` | No | Project type: web-app, api, library, cli, docker, other |
| `--language` | No | Primary language: typescript, python, go, rust, etc. |

## What It Does

### 1. Validates Location

Reads `development.projects_root` from `paths-registry.yaml` (e.g., `~/Code`).

**If not set**: Prompts user to set it first or uses `~/Code` as default.

### 2. Creates Project Directory

```bash
# In projects_root, NOT in AIfred
mkdir -p ~/Code/my-new-project
cd ~/Code/my-new-project
```

### 3. Initializes Project

Based on type/language, creates appropriate structure:

**Default (any type)**:
```
my-new-project/
├── .git/                    # git init
├── .claude/
│   └── CLAUDE.md            # Project-specific instructions
├── README.md                # Basic readme
└── .gitignore               # Language-appropriate ignores
```

**Type-specific additions**:
- `web-app`: package.json, src/, public/
- `api`: package.json or requirements.txt, src/, tests/
- `cli`: src/, bin/
- `library`: src/, tests/, docs/
- `docker`: docker-compose.yml, Dockerfile

### 4. Creates Project CLAUDE.md

```markdown
# [Project Name]

**Type**: [type]
**Language**: [language]
**Created**: [date]
**Hub**: [path to AIfred installation]

## Purpose

[User fills in]

## Key Commands

[Based on type - e.g., npm run dev, python main.py]

## Notes

[User fills in]
```

### 5. Registers with AIfred

Updates `paths-registry.yaml`:

```yaml
development:
  projects:
    my-new-project:
      path: "~/Code/my-new-project"
      type: "api"
      language: "typescript"
      status: "active"
      created: "2025-01-01"
      context_file: ".claude/context/projects/my-new-project.md"
```

### 6. Creates Context File in AIfred

Creates `.claude/context/projects/[name].md` in AIfred (not in the project):

```markdown
# [Project Name]

**Path**: ~/Code/my-new-project
**Type**: [type]
**Language**: [language]
**Status**: active
**Created**: [date]

## Overview

[To be filled in as project develops]

## Key Decisions

[Log important architectural decisions here]

## Current State

[Updated during sessions working on this project]
```

### 7. Optional: GitHub Setup

If `github_enabled` is true, prompts:

"Would you like to create a GitHub repo for this project?"
- Yes, create public repo
- Yes, create private repo
- No, just local git

---

## Key Concept

**AIfred is a hub, not a container.**

- Project code goes in `~/Code/my-new-project`
- Project context/notes go in AIfred at `.claude/context/projects/my-new-project.md`
- AIfred tracks and orchestrates, but doesn't hold the actual code

---

## Related Commands

- `/register-project` - Register an existing project with AIfred
- `/list-projects` - Show all registered projects
- `/project-status` - Show status of a specific project

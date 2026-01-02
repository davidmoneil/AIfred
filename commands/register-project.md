# /register-project

Register an existing project with AIfred so it can track and assist with it.

## Usage

```
/register-project <path> [--type <type>] [--language <lang>]
```

**Examples**:
```
/register-project ~/Code/grc-platform
/register-project ~/Code/time-scheduler --type web-app --language typescript
/register-project ~/CreativeProjects --type other --language markdown
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `path` | Yes | Path to existing project directory |
| `--type` | No | Project type: web-app, api, library, cli, docker, other |
| `--language` | No | Primary language (auto-detected if not specified) |

## What It Does

### 1. Validates Project Exists

```bash
# Check path exists and is a directory
[ -d "$path" ] || error "Directory not found"
```

### 2. Auto-Detects Project Properties

**Language detection**:
```bash
# Check for language indicators
[ -f "package.json" ] && language="javascript/typescript"
[ -f "requirements.txt" ] && language="python"
[ -f "go.mod" ] && language="go"
[ -f "Cargo.toml" ] && language="rust"
```

**Type detection**:
```bash
# Check for type indicators
[ -f "docker-compose.yml" ] && type="docker"
[ -d "src" ] && [ -f "package.json" ] && type="web-app"
```

### 3. Gathers Project Info

Prompts user for any missing information:

- Project name (default: directory name)
- Type (if not detected or specified)
- Language (if not detected or specified)
- Brief description

### 4. Updates paths-registry.yaml

Adds project to the registry:

```yaml
development:
  projects:
    grc-platform:
      path: "~/Code/grc-platform"
      type: "web-app"
      language: "typescript"
      repo: "github.com/user/grc-platform"  # if .git/config has remote
      status: "active"
      registered: "2025-01-01"
      context_file: ".claude/context/projects/grc-platform.md"
      notes: "User-provided description"
```

### 5. Creates Context File in AIfred

Creates `.claude/context/projects/[name].md`:

```markdown
# [Project Name]

**Path**: [path]
**Type**: [type]
**Language**: [language]
**Status**: active
**Registered**: [date]

## Overview

[From user description or "To be documented"]

## Key Files

[Auto-populated from project structure]
- README.md (if exists)
- package.json / requirements.txt (if exists)
- docker-compose.yml (if exists)

## Current State

[To be updated during work sessions]

## Key Decisions

[To be logged as project develops]
```

### 6. Creates Symlink (Optional)

If user wants quick access:

```bash
ln -s ~/Code/grc-platform external-sources/projects/grc-platform
```

---

## Key Concept

**AIfred tracks projects, it doesn't contain them.**

The project stays at its original location. AIfred just knows about it and maintains context/notes in its own `.claude/context/projects/` directory.

---

## Batch Registration

To register multiple projects at once:

```
/register-project ~/Code/project1 ~/Code/project2 ~/Code/project3
```

Or register all projects in a directory:

```
/register-project ~/Code/*
```

---

## Related Commands

- `/create-project` - Create a new project from scratch
- `/list-projects` - Show all registered projects
- `/unregister-project` - Remove project from AIfred tracking

---
description: Coding Project Management
argument-hint: <action> [project] [args]
skill: project-lifecycle
allowed-tools:
  - Read
  - Task
  - Glob
---

# /code - Coding Project Management

Manage coding projects with intelligent agents for analysis, implementation, and testing.

## Usage

```
/code <action> [project] [args]
```

## Actions

| Action | Usage | Description |
|--------|-------|-------------|
| `list` | `/code list [--archived]` | List all coding projects |
| `new` | `/code new <name> [stack]` | Create new project |
| `analyze` | `/code analyze <project> [--task "desc"]` | Run code-analyzer agent |
| `implement` | `/code implement <project> "task"` | Run code-implementer agent |
| `test` | `/code test <project> [flow]` | Run code-tester agent |
| `status` | `/code status <project>` | Show project details |
| `archive` | `/code archive <project> [--hard]` | Archive inactive project |
| `restore` | `/code restore <project>` | Restore from archive |

## Stacks

`nextjs-supabase`, `python-fastapi`, `static-site`, `custom`

## Example Workflows

**Starting work on a project**:
1. `/code status my-project` - Check current state
2. `/code analyze my-project --task "add feature X"` - Understand codebase
3. `/code implement my-project "Add feature X"` - Implement
4. `/code test my-project` - Verify

**Creating a new project**:
1. `/code new my-app nextjs-supabase` - Create structure
2. `/code analyze my-app` - Verify detection

## Project Locations

All projects live in the configured projects directory.
Context files are in `.claude/context/projects/`.
Agent definitions are in `.claude/agents/code-*.md`.

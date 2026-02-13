---
argument-hint: <project-name> [type]
description: Create a new project with semi-automated setup
skill: project-lifecycle
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(git:*)
---

Create a new project: **$ARGUMENTS**

## Step 1: Parse Arguments

Extract:
- Project name (required): First argument
- Project type (optional): Second argument (writing, coding, research, operations, other)
- If type not provided, ask user to choose

## Step 2: Validate Project Request

1. **Normalize project name** to slug format (lowercase, hyphens, no special chars)
2. **Check if project already exists** in `.claude/projects/`
3. **Search for similar projects** in `_index.md`

## Step 3: Gather Project Configuration

Ask user for:
1. Brief description (1-2 sentences)
2. Primary agent (optional, suggest based on type)
3. Specific goals (optional)

## Step 4: Create Project Structure

```bash
mkdir -p .claude/projects/<project-name>/{examples,knowledge,archive}
```

Copy template files from `.claude/templates/project-template/` and populate variables.

## Step 5: Initialize Type-Specific Knowledge

Create type-appropriate knowledge files (style-guide, coding-standards, research-framework, or automation-guide).

## Step 6: Update Project Registry

Add entry to `.claude/projects/_index.md`.

## Step 7: Create Initial Git Commit

Stage and commit the new project files.

## Step 8: Return Success Summary

Show created files, location, and next steps.

## Examples

```bash
/create-project ciso-blog-writing
/create-project homelab-automation operations
/create-project kubernetes-learning
```

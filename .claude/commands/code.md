---
description: /code - Coding Project Management
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

### List Projects
```
/code list [--archived]
```
List all coding projects with status. Use `--archived` to include archived projects.

### Create New Project
```
/code new <name> [stack]
```
Create a new project with standard structure.

**Stacks**: `nextjs-supabase`, `python-fastapi`, `static-site`, `custom`

**Example**: `/code new inventory-app nextjs-supabase`

### Analyze Project
```
/code analyze <project> [--task "<description>"]
```
Run code-analyzer to understand project structure. Optionally focus on a specific task.

**Example**: `/code analyze grc-platform --task "add user roles"`

### Implement Changes
```
/code implement <project> "<task>"
```
Implement a feature or fix using code-implementer agent.

**Example**: `/code implement grc-platform "Add user role management to dashboard"`

### Test Project
```
/code test <project> [flow]
```
Run tests and/or Playwright user flows using code-tester agent.

**Examples**:
- `/code test grc-platform` - Run all tests
- `/code test grc-platform login` - Test login flow only

### Project Status
```
/code status <project>
```
Show project details, recent changes, and current state.

### Archive Project
```
/code archive <project> [--hard]
```
Archive an inactive project. Use `--hard` for full archive (move to archive folder).

### Restore Project
```
/code restore <project>
```
Restore a project from archive.

### Learn Pattern
```
/code learn "<pattern description>"
```
Explicitly save a pattern to Memory MCP for future use.

---

## Prompt

You are managing coding projects through the coding agent system.

### Available Information

**Projects Registry**: `.claude/context/coding/_index.md`
**Stack Templates**: `.claude/context/coding/stack-templates.md`
**paths-registry**: `paths-registry.yaml` under `coding:` section

### Action Handlers

**For `list`**:
1. Read `.claude/context/coding/_index.md`
2. Display formatted table of projects
3. Show status, stack, last activity

**For `new`**:
1. Create directory in `~/Code/{name}/`
2. Apply stack template from `stack-templates.md`
3. Initialize git repository
4. Create context file in `.claude/context/coding/{name}.md`
5. Update paths-registry.yaml
6. Report next steps

**For `analyze`**:
Use the Task tool to launch the code-analyzer agent:
```
Task(
  subagent_type="general-purpose",
  prompt="You are the code-analyzer agent. [load .claude/agents/code-analyzer.md]
         Project: {project}
         Task: {task if provided}

         Follow the agent workflow and return analysis results."
)
```

**For `implement`**:
Use the Task tool to launch the code-implementer agent:
```
Task(
  subagent_type="general-purpose",
  prompt="You are the code-implementer agent. [load .claude/agents/code-implementer.md]
         Project: {project}
         Task: {task}

         Follow the agent workflow, implement changes, and manage git."
)
```

**For `test`**:
Use the Task tool to launch the code-tester agent:
```
Task(
  subagent_type="general-purpose",
  prompt="You are the code-tester agent. [load .claude/agents/code-tester.md]
         Project: {project}
         Flow: {flow if provided, else 'all'}

         Follow the agent workflow, run tests, capture screenshots."
)
```

**For `status`**:
1. Read project context file
2. Check git status in project directory
3. Check if services are running (ports)
4. Display comprehensive status

**For `archive`**:
1. Update project context with archived status
2. Update `_index.md` to move to archived section
3. If `--hard`: move context file to archive folder
4. Preserve Memory MCP entities

**For `restore`**:
1. Move context file from archive
2. Update `_index.md` to active section
3. Run `/code analyze` to refresh understanding

**For `learn`**:
1. Parse the pattern description
2. Create Memory MCP entity (CodingPattern type)
3. Confirm pattern saved

### Project Locations

All projects live in `~/Code/` directory.
Project context files are in `.claude/context/coding/`.
Agent definitions are in `.claude/agents/code-*.md`.

### Example Workflows

**Starting work on a project**:
1. `/code status grc-platform` - Check current state
2. `/code analyze grc-platform --task "add feature X"` - Understand codebase
3. `/code implement grc-platform "Add feature X"` - Implement
4. `/code test grc-platform` - Verify it works

**Creating a new project**:
1. `/code new my-app nextjs-supabase` - Create structure
2. Follow setup instructions
3. `/code analyze my-app` - Verify structure detected

### Error Handling

If project not found:
- Check if it exists in paths-registry.yaml
- Suggest `/code list` to see available projects
- Offer to create if new

If agent fails:
- Report error details
- Suggest troubleshooting steps
- Check if services are running

### Response Format

Always provide clear, actionable output:
- Use tables for lists
- Show file paths for context
- Include next steps
- Link to relevant documentation

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

Create a new Claude Code project: **$ARGUMENTS**

## Step 1: Parse Arguments

Extract:
- Project name (required): First argument
- Project type (optional): Second argument (writing, coding, research, operations, other)
- If type not provided, ask user to choose

Valid types:
- **writing**: Blog posts, documentation, articles
- **coding**: Software development projects
- **research**: Technical deep-dives, investigations
- **operations**: Infrastructure, DevOps, automation
- **other**: Custom project type

## Step 2: Validate Project Request

1. **Normalize project name** to slug format:
   - Lowercase
   - Replace spaces with hyphens
   - Remove special characters
   - Example: "CISO Blog Writing" → "ciso-blog-writing"

2. **Check if project already exists:**
   ```bash
   ls -la .claude/projects/ | grep -i <normalized-name>
   ```
   - If exists: Error and show existing project
   - If similar projects found: Ask if user wants to use existing or create new

3. **Search for similar projects:**
   - Load @.claude/projects/_index.md
   - Look for projects with similar names or types
   - If found, inform user and ask if they want to continue

## Step 3: Gather Project Configuration

Ask user for:

1. **Brief description** (1-2 sentences):
   - What is this project about?
   - What will you create/achieve?

2. **Primary agent** (optional):
   - Which agent will mainly work on this?
   - Suggest based on type:
     - writing → writer
     - coding → developer
     - research → research
     - operations → devops

3. **Specific goals** (optional):
   - Any success criteria?
   - Deliverables expected?

## Step 4: Create Project Structure

1. **Create directories:**
   ```bash
   mkdir -p .claude/projects/<project-name>/{examples,knowledge,archive}
   ```

2. **Copy template files:**
   - Copy from @.claude/templates/project-template/
   - All files: README.md, config.yaml, todo.md, learned-patterns.md, progress.md, knowledge/

3. **Populate template variables:**
   - Replace `[project-name]` with normalized name
   - Replace `[Project Title]` with proper title
   - Replace `[description]` with user's description
   - Replace `[primary-agent]` with chosen agent
   - Replace `[created-date]` with today's date
   - Replace `[created-by]` with "David Moneil"
   - Replace `[project-type]` with chosen type

## Step 5: Initialize Type-Specific Knowledge

Based on project type, create initial knowledge files:

### For Writing Projects
Create `knowledge/style-guide.md`:
```markdown
# Style Guide

## Voice & Tone
- Conversational but authoritative
- Active voice preferred
- Avoid jargon unless necessary

## Structure
- Executive summary (2-3 sentences)
- Problem statement
- Solution/approach
- Conclusion

## Length
- Target: 500-750 words
- Max: 1000 words
```

### For Coding Projects
Create `knowledge/coding-standards.md`:
```markdown
# Coding Standards

## Language
- Python 3.12+
- Type hints required
- Docstrings for all public functions

## Style
- Black formatting
- Ruff linting
- Maximum line length: 120 characters

## Testing
- pytest for unit tests
- Minimum 80% coverage
```

### For Research Projects
Create `knowledge/research-framework.md`:
```markdown
# Research Framework

## Process
1. Define research question
2. Gather sources
3. Analyze findings
4. Document conclusions

## Output Format
- Executive summary
- Detailed findings
- Recommendations
- References
```

### For Operations Projects
Create `knowledge/automation-guide.md`:
```markdown
# Automation Guide

## Systems
- List systems involved
- Access requirements
- Dependencies

## Safety
- Always test in dev first
- Document rollback procedures
- Never automate destructive operations without approval
```

## Step 6: Update Project Registry

1. **Read current index:**
   - Load @.claude/projects/_index.md

2. **Add new project entry:**
   ```markdown
   ### [Project Title]
   - **Path**: `.claude/projects/<project-name>/`
   - **Type**: [project-type]
   - **Primary Agent**: [primary-agent]
   - **Created**: [created-date]
   - **Status**: Active
   - **Description**: [description]
   ```

3. **Write updated index:**
   - Update the file with new entry
   - Keep sorted by status (Active first)

## Step 7: Create Initial Git Commit

1. **Stage new project:**
   ```bash
   cd $AIFRED_HOME
   git add .claude/projects/<project-name>/
   git add .claude/projects/_index.md
   ```

2. **Create commit:**
   ```bash
   git commit -m "Create project: [Project Title]

   Type: [project-type]
   Primary agent: [primary-agent]
   Created: [created-date]

   [description]

   Initial structure:
   - Project configuration
   - Knowledge templates
   - Empty examples and progress tracking"
   ```

3. **Check git status:**
   ```bash
   git status
   ```

## Step 8: Return Success Summary

Output:
```
✅ Project created: [Project Title]

📁 Location: .claude/projects/<project-name>/
🤖 Primary Agent: [primary-agent]
📋 Type: [project-type]
📅 Created: [created-date]

📝 Files created:
- README.md
- config.yaml
- todo.md
- learned-patterns.md
- progress.md
- knowledge/ (with type-specific guides)

✅ Git: Committed to local repository

Next steps:
1. Review project structure: cd .claude/projects/<project-name>/
2. Customize config.yaml if needed
3. Add your first todo to todo.md
4. Start working - the system will learn as you go!

To start: Just begin working in this project context
Or: "Load project: [project-name]"
```

## Error Handling

**If project exists:**
```
❌ Project '<project-name>' already exists

Location: .claude/projects/<project-name>/
Created: <date>
Status: <status>

Options:
1. Open existing project
2. Choose a different name
3. Archive old and create new
```

**If validation fails:**
```
❌ Invalid project name: [reason]

Valid names:
- Lowercase letters, numbers, hyphens
- No spaces or special characters
- 3-50 characters long

Example: ciso-blog-writing
```

## Examples

```bash
# Simple creation
/create-project ciso-blog-writing

# With type specified
/create-project homelab-automation operations

# Will prompt for type
/create-project kubernetes-learning
```

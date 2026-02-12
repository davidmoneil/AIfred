# Obsidian Collaboration Pattern

**Created**: 2026-01-02
**Status**: Active
**Purpose**: Define how Claude Code sessions use Obsidian as a collaboration layer for rich feedback, session documentation, and persistent knowledge capture.

---

## Overview

This pattern establishes Obsidian as a **session collaboration workspace** where:
- Claude creates structured artifacts (questions, session logs, decisions, todos)
- User responds with rich content (tables, lists, formatting)
- Conversation continues in Claude Code terminal
- Artifacts persist as searchable, navigable knowledge

**Key Benefits**:
- Rich formatting for complex feedback (tables, lists, diagrams)
- Persistent audit trail of decisions and rationale
- Todo aggregation across sessions via Obsidian plugins
- Visual navigation (graph view, folders, backlinks)
- Context window efficiency (complex content stays in files until needed)

---

## Dual Output Principle

**Claude always responds in terminal** so user can see content regardless of Obsidian access.

| Claude Action | Terminal | Obsidian |
|---------------|----------|----------|
| Responses/explanations | Always shown | Optionally documented |
| Questions | Summary/full text shown | Full detail in file |
| Decisions | Announced | Full record in file |
| Session notes | Summary at end | Full detail in file |

**User Response Options**:
- **Terminal**: Quick responses, when away from Obsidian, simple answers
- **Obsidian inbox**: Rich responses with tables, lists, formatting

**Fallback Mode**: User says "no Obsidian access" or "terminal only" - Claude continues documenting to Obsidian but shows all content in terminal for user interaction.

---

## Vault Location

**Primary Workspace**: `/mnt/synology_nas/Obsidian/Master/AI-Sessions/`

This folder lives within the Master vault to:
- Maintain access to all existing content (creative projects, references)
- Enable cross-linking between session artifacts and vault content
- Use existing sync and backup infrastructure

---

## Folder Structure

```
AI-Sessions/
├── _index.md                  # Navigation and recent sessions
├── _inbox.md                  # Standard response location (user writes here)
├── _dashboard.md              # Dataview aggregation (todos, decisions, open questions)
├── _templates/
│   ├── session-template.md    # New session starter
│   ├── question-template.md   # Question for user
│   └── decision-template.md   # Decision record
├── YYYY/                      # Year folder
│   └── MM/                    # Month folder
│       └── DD-topic-name/     # Session folder
│           ├── session-notes.md
│           ├── questions/
│           │   └── q1-topic.md
│           ├── decisions/
│           │   └── d1-topic.md
│           └── todos.md
```

---

## Key Files

### `_inbox.md` - Standard Response Location

When Claude creates a question or needs feedback, user responses go here by default.

**Format**:
```markdown
# Response Inbox

## Current Response

> **Responding to**: [[2026/01/02-obsidian-integration/questions/q1-approach]]
> **Date**: 2026-01-02

[User's rich response here - tables, lists, etc.]

---

## Previous Responses

[Archived after Claude reads them]
```

**Workflow** (100% Consistent - Every Time):
1. Claude creates question file, mentions `_inbox.md` as response location
2. User writes response in `_inbox.md` with link to question
3. User tells Claude "I've responded" (or "check inbox")
4. Claude reads `_inbox.md`
5. **Claude copies** full response text to session folder:
   - Into question file's `## Response` section, OR
   - As separate file `responses/r1-topic.md` if complex
6. **Claude archives** response in `_inbox.md`:
   - Move content from "Current Response" to "Previous Responses"
   - Clear "Current Response" for next use
7. Claude continues conversation in terminal

**Implementation**: Uses Edit tool for exact text preservation. No summarization, no bash commands.

### `_dashboard.md` - Aggregation View

Uses Dataview (if available) to show:
- Open todos across all sessions
- Recent decisions
- Unanswered questions
- Session timeline

### Session Folder Structure

Each significant session gets a dated folder:
- `session-notes.md` - Main log (what was discussed, outcomes)
- `questions/` - Questions requiring user input
- `decisions/` - Decisions made with rationale
- `todos.md` - Task list (Tasks plugin compatible)

---

## Workflow Patterns

### Pattern 1: Rich Feedback Request

When Claude needs complex input from user:

1. **Claude creates question file** in session's `questions/` folder
2. **Claude instructs**: "I've created a question at `[path]`. Please respond in `_inbox.md`"
3. **User responds** in `_inbox.md` with rich formatting
4. **User confirms**: "I've responded"
5. **Claude reads** `_inbox.md` and continues

### Pattern 2: Session Documentation

At session end or key checkpoints:

1. **Claude creates/updates** `session-notes.md` with:
   - Summary of work done
   - Decisions made (with links to decision docs)
   - Open questions
   - Next steps
2. **Todos** written to `todos.md` in Tasks-compatible format

### Pattern 3: Decision Recording

For significant decisions:

1. **Claude creates** decision doc in `decisions/` folder
2. **Format includes**:
   - Context/background
   - Options considered
   - Decision made
   - Rationale
   - Date and participants

---

## File Formats

### Question File

```markdown
---
type: question
status: open  # open | answered | resolved
created: 2026-01-02
session: 2026/01/02-obsidian-integration
---

# Question: [Topic]

## Context

[Why this question is being asked]

## Question

[The actual question - can include options, considerations]

## Response Location

Please respond in [[_inbox.md]] with a link back to this question.

## Response

[Filled in after user responds, or link to inbox response]
```

### Decision File

```markdown
---
type: decision
status: final  # draft | final | superseded
created: 2026-01-02
session: 2026/01/02-obsidian-integration
---

# Decision: [Topic]

## Context

[Background and why decision was needed]

## Options Considered

1. **Option A**: [Description]
   - Pros: ...
   - Cons: ...

2. **Option B**: [Description]
   - Pros: ...
   - Cons: ...

## Decision

[What was decided]

## Rationale

[Why this option was chosen]

## Implications

[What this means for future work]
```

### Task Format (Tasks Plugin)

When creating tasks in Obsidian, use these formats for Tasks plugin compatibility:

**Checkbox States**:

| Syntax | Meaning | When to Use |
|--------|---------|-------------|
| `- [ ]` | Todo | Standard task |
| `- [/]` | In Progress | Task started but not complete |
| `- [x]` | Done | Task completed |
| `- [-]` | Cancelled | Won't do / no longer relevant |
| `- [!]` | Important | High priority, needs attention |
| `- [?]` | Question | Needs clarification before proceeding |

**Priority** (add before task text):
- `🔺` High priority
- `🔼` Medium priority
- `🔽` Low priority

**Due Dates** (add after task text):
- `📅 2026-01-15` - Due date

**Tags** (add at end):
- `#ai-session` - Include in AI-Sessions dashboard queries
- `#project-name` - Group by project

**Examples**:
```markdown
- [ ] Review plugin architecture #ai-session
- [!] Fix security vulnerability 🔺 📅 2026-01-03 #ai-session
- [/] Implementing provider abstraction #my-ai-plugin
- [?] Which database to use for embeddings? #ai-session
```

**Claude's Task Creation Rule**: When creating todos in Obsidian, always use this format. Include `#ai-session` tag for visibility in dashboard.

---

### Session Notes File

```markdown
---
type: session
date: 2026-01-02
topic: Obsidian Integration Design
status: complete  # active | complete
---

# Session: [Topic]

## Summary

[Brief summary of what was accomplished]

## Work Done

- [Item 1]
- [Item 2]

## Decisions Made

- [[decisions/d1-topic]] - [Brief description]

## Open Questions

- [[questions/q1-topic]] - [Brief description]

## Next Steps

- [ ] Task 1
- [ ] Task 2

## Related

- [[link to related content]]
```

---

## Integration with Claude Code

### When to Create Obsidian Artifacts

| Situation | Action |
|-----------|--------|
| Need complex feedback with formatting | Create question file, direct to `_inbox.md` |
| Significant decision made | Create decision file |
| Session ending | Update/create session notes |
| Multi-step task with todos | Write todos.md in session folder |

### Reading User Responses

Standard check:
```
Read: /mnt/synology_nas/Obsidian/Master/AI-Sessions/_inbox.md
```

### Creating Session Folders

Path pattern: `/mnt/synology_nas/Obsidian/Master/AI-Sessions/YYYY/MM/DD-topic-name/`

Example: `/mnt/synology_nas/Obsidian/Master/AI-Sessions/2026/01/02-obsidian-integration/`

---

## Relationship to Hub

| Content Type | Location | Reason |
|--------------|----------|--------|
| **Design patterns** | Hub `.claude/context/patterns/` | Reusable across projects |
| **Standards** | Hub `.claude/context/standards/` | Project governance |
| **Session artifacts** | Obsidian `AI-Sessions/` | User collaboration, visual navigation |
| **Project context** | Hub `.claude/context/projects/` | Technical project docs |
| **Session state** | Hub `.claude/context/session-state.md` | Claude's working memory |

**Rule**: Default documentation goes to the hub unless explicitly requested for Obsidian.

---

## Future Enhancements

### Phase 2: Plugin Integration ✅ COMPLETE (2026-01-02)
- [x] Review installed Obsidian plugins (20+ found)
- [x] Dataview queries for dashboard (activated)
- [x] Tasks plugin compatibility verification (custom statuses documented)
- [ ] Templater integration for file creation (available, not yet configured)

### Phase 3: Automation
- [ ] Hook to auto-create session folders
- [ ] Template insertion commands
- [ ] Sync patterns between hub and Obsidian

### Phase 4: My AI Plugin Integration
- [ ] Plugin reads session context
- [ ] Plugin can create artifacts
- [ ] Unified AI experience across Claude Code and Obsidian

---

## Related Documentation

- **Documentation Location Standard**: `.claude/context/standards/documentation-location.md`
- **Session Exit Procedure**: `.claude/context/workflows/session-exit-procedure.md`
- **Memory Storage Pattern**: `.claude/context/patterns/memory-storage-pattern.md`

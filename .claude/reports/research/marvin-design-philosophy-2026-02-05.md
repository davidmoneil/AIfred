# Marvin Design Philosophy Report

**Date**: 2026-02-05  
**Repository**: https://github.com/SterlingChin/marvin-template  
**Research Focus**: Consistency and predictability mechanisms in the "Chief of Staff" AI pattern

---

## Executive Summary

Marvin achieves consistent, predictable user experience through **architectural separation**, **structured file-based state**, and **standardized command patterns**. The core design principle is **workspace isolation** — template code stays separate from user data, enabling non-destructive updates. Every workflow follows a fixed pattern enforced by markdown-based commands and skills with YAML frontmatter metadata.

**Key Consistency Mechanisms**:
1. **Dual-directory architecture** (template vs. workspace) prevents update conflicts
2. **Structured state files** with mandatory schemas (`state/current.md`, `state/goals.md`)
3. **Session continuity protocol** with date-based file naming
4. **Frontmatter-driven skill system** for behavior validation
5. **Setup script standardization** for integration reliability
6. **File-based commands** (not in-context) for reproducible behavior

---

## Workflow Engineering

### Consistency Mechanisms

#### 1. Workspace Separation Architecture

The most critical design decision is **template-workspace separation**:

```
~/Downloads/marvin-template/  ← Template (update source)
├── .marvin/                  ← Setup scripts & integrations
├── .claude/commands/         ← Slash command definitions
└── skills/                   ← Behavioral templates

~/marvin/                     ← Workspace (user data)
├── CLAUDE.md                 ← User profile
├── state/                    ← Goals & priorities
├── sessions/                 ← Daily logs
├── .marvin-source            ← Points to template
└── [receives template copy]
```

**Mechanism**: The `.marvin-source` file creates a **pointer relationship**. The `/sync` command:
1. Reads `.marvin-source` to find template location
2. Copies NEW commands/skills only (never overwrites user data)
3. Preserves all user customizations

**Result**: Users can `git pull` template updates without destroying personal state.

#### 2. Session Lifecycle Protocol

Every session follows the same initialization pattern:

**`/start` workflow** (from `.claude/commands/start.md`):
```
1. Run `date +%Y-%m-%d` → store as TODAY
2. Read CLAUDE.md (user profile)
3. Read state/current.md (priorities)
4. Read state/goals.md (goals)
5. Check sessions/{TODAY}.md
   - Exists → resume session
   - Missing → read yesterday's session for continuity
6. Present briefing (fixed format)
```

This **ordered file-read protocol** ensures identical context loading every time.

**`/end` workflow** (from `.claude/commands/end.md`):
```
1. Extract from conversation:
   - Topics discussed
   - Decisions made
   - Open threads
   - Action items
2. Append to sessions/{TODAY}.md with timestamp
3. Update state/current.md
4. Confirm (standardized output)
```

**`/update` workflow** (lightweight checkpoint):
```
1. Brief scan for changes (no full summary)
2. Append to sessions/{TODAY}.md
3. Update state/current.md ONLY if something changed
4. Minimal confirmation (one line)
```

**Drift Prevention**: Fixed schemas prevent workflow variation. Commands are **files**, not in-context prompts, so they can't drift over time.

#### 3. Date-Based File Naming

All session files use `YYYY-MM-DD.md` naming from `date +%Y-%m-%d`. This creates:
- **Chronological ordering** (filesystem sorts correctly)
- **No ambiguity** (one date → one file)
- **Easy continuity** (yesterday's file is yesterday's date)

### Template Patterns

#### Skills with YAML Frontmatter

Every skill uses **YAML frontmatter** to declare its behavior contract:

```yaml
---
name: content-shipped
description: |
  Log shipped content to the content log. Use when user says "I shipped", 
  "I published", "just posted", or mentions completing content work.
license: MIT
compatibility: marvin
metadata:
  marvin-category: content
  user-invocable: false
  slash-command: null
  model: default
  proactive: true
---
```

**Metadata fields**:
- `user-invocable`: Can user call this directly?
- `slash-command`: If yes, what's the command?
- `proactive`: Should Marvin detect and trigger automatically?
- `marvin-category`: session, work, content, research, communication, meta

This metadata enables **behavior validation**. Claude can introspect its own capabilities.

#### Skill Template Structure

All skills follow the same markdown structure (`skills/_template/SKILL.md`):

```markdown
# Skill Name

## When to Use
- Trigger condition 1
- Trigger condition 2

## Process
### Step 1: First Step
### Step 2: Second Step
### Step 3: Third Step

## Output Format
[Expected output template]

---
*Skill created: YYYY-MM-DD*
```

This creates **structural predictability** — every skill is a recipe.

#### Command Structure

Slash commands are markdown files in `.claude/commands/`:

```markdown
---
description: [Brief description for help system]
---

# /command-name - Title

[Purpose statement]

## Instructions

### 1. Step One
[Explicit bash commands or file operations]

### 2. Step Two
[More explicit instructions]
```

**Result**: Commands are **deterministic recipes**, not conversational requests.

### Edge Case Handling

#### Missing Files

**Pattern**: Always provide fallback defaults.

Example from `/start`:
```
3. Read sessions/{TODAY}.md — If exists, we're resuming today's session
4. If no today file, read the most recent file in sessions/ for continuity
```

#### Empty State

**Pattern**: Placeholder content with setup instructions.

Example `state/current.md` before setup:
```markdown
# Current State

<!-- SETUP NOT COMPLETE: This file has placeholder content -->
<!-- MARVIN will update this during setup -->

## Active Priorities
1. [Complete MARVIN setup first]
```

#### Merge Conflicts (Workspace Already Exists)

From `setup.sh`:
```bash
if [[ -d "$WORKSPACE_DIR" ]]; then
    print_color "$YELLOW" "Warning: $WORKSPACE_DIR already exists."
    read -p "Continue and merge with existing? [y/N]: " CONTINUE_MERGE
    if [[ ! "$CONTINUE_MERGE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
```

**Pattern**: Warn → Confirm → Safe merge (copy template, let user data overwrite).

---

## Documentation System

### Philosophy

**"Documentation serves retrieval, not explanation."**

Marvin's documentation is:
1. **File-based** (not conversation-based) — persistent across sessions
2. **Structured** (fixed schemas) — parseable, not prose
3. **Incremental** (append-only sessions) — complete history
4. **Self-referential** (files point to files) — `.marvin-source`, session continuity

### Structure Standards

#### Session Logs (`sessions/YYYY-MM-DD.md`)

**Schema** (from `end` skill):
```markdown
# Session Log: YYYY-MM-DD

## Session: HH:MM
### Topics
- {topic 1}
- {topic 2}

### Decisions
- {decision 1}

### Shipped
- {content shipped, if any}

### Open Threads
- {thread 1}

### Next Actions
- {action 1}

## Update: HH:MM
- {brief note}
```

**Always captured**:
- Timestamp (for session ordering)
- Topics (what was worked on)
- Decisions (commitments made)
- Open threads (continuity for next session)
- Next actions (explicit handoff)

#### State Schema (`state/current.md`)

```markdown
# Current State

Last updated: YYYY-MM-DD

## Active Priorities
1. [Priority with context]
2. [Priority with context]

## Open Threads
- [Thread description]

## Recent Context
- [Recent work or decisions]
```

**Mandatory fields**: Last updated, Active Priorities, Open Threads, Recent Context

#### Goals Schema (`state/goals.md`)

```markdown
# Goals

Last updated: YYYY-MM-DD

## This Year
[User's annual goals]

## Tracking

| Goal | Status | Notes |
|------|--------|-------|
| [Goal] | [Status] | [Notes] |
```

**Progress tracking**: Table format for scannable status.

#### Content Log (`content/log.md`)

```markdown
## YYYY-MM

### YYYY-MM-DD
- **[TYPE]** "Title"
  - URL: {link}
  - Platform: {where published}
  - Goal: {which goal this supports}
```

**Types**: VIDEO, ARTICLE, POST, EVENT, PODCAST, CODE, OTHER

### Metadata Capture

**Always recorded**:
- Dates (via `date +%Y-%m-%d` command)
- Last updated timestamps in state files
- Skill creation dates (`*Skill created: YYYY-MM-DD*`)
- Git commit co-authorship (`Co-Authored-By: Claude <noreply@anthropic.com>`)

**Why**: Enables retrospective analysis and audit trail.

---

## State Architecture

### File Organization

**Mandated structure**:
```
workspace/
├── CLAUDE.md              # User profile (read on startup)
├── .marvin-source         # Template location pointer
├── state/
│   ├── current.md         # Priorities & open threads
│   ├── goals.md           # Annual/monthly goals
│   └── todos.md           # Task list (optional)
├── sessions/
│   └── YYYY-MM-DD.md      # One file per day
├── content/
│   └── log.md             # Shipped content
├── reports/               # Generated summaries
├── skills/                # Copied from template
└── .claude/commands/      # Copied from template
```

**User data** (never overwritten):
- `state/`, `sessions/`, `content/`, `reports/`, `CLAUDE.md`, `.env`

**Template data** (synchronized via `/sync`):
- `.claude/commands/`, `skills/`

### State Schema

#### CLAUDE.md (Master Configuration)

**Structure** (generated by `setup.sh`):
```markdown
# MARVIN - AI Chief of Staff

## Part 1: Who You Are
**Name:** {user name}
**Role:** {role at company}

### Goals
{user goals from setup}

## Part 2: How MARVIN Behaves
### Core Principles
1. Proactive by default
2. Maintain continuity
3. Track progress
4. Save before compact

### Personality
{professional/casual/sarcastic}

## Part 3: System Architecture
[Directory structure documentation]
[Session continuity protocol]
[Slash commands reference]

## Part 4: Evolution
This system is designed to evolve...
```

**Key design**: The master config is **user-owned** and **self-documenting**.

### Migration Strategy

The `migrate.sh` script demonstrates **backwards-compatible state evolution**:

**Process**:
1. Detect old installation (check for `CLAUDE.md`)
2. Create new workspace directory
3. Copy latest template structure
4. Overlay user's personal data (overwrites template defaults)
5. Create `.marvin-source` pointer
6. Initialize git with migration commit

**Preserved data**:
- `CLAUDE.md` (profile)
- `state/*` (goals, priorities)
- `sessions/*` (all session history)
- `reports/*`, `content/*`
- `.env` (secrets)
- Custom skills (not in template)

**Pattern**: Template-first, user-data-overlay. Ensures latest structure with preserved personalization.

---

## Command Design

### Consistency Patterns

#### 1. File-Based Commands

Commands are **markdown files**, not in-context instructions. This prevents:
- Prompt drift over time
- Inconsistent interpretation
- Context-dependent behavior

#### 2. Bash Commands Embedded

Commands include **exact bash syntax**:

From `/start`:
```markdown
### 1. Establish Date
Run `date +%Y-%m-%d` to get today's date. Store as TODAY.
```

**Not** "get the current date" (ambiguous), but **exact command**.

#### 3. File Read Order

Commands specify **ordered operations**:

From `/start`:
```markdown
### 2. Load Context (read these files in order)
- `CLAUDE.md` - Core instructions and context
- `state/current.md` - Current priorities and state
- `state/goals.md` - Your goals
- `sessions/{TODAY}.md` - If exists, we're resuming today's session
```

**Result**: Same context load, same order, every time.

#### 4. Fixed Output Templates

Commands specify **output structure**:

From `/start`:
```markdown
## Output Format

Good morning! It's {Day}, {Date}.

**Today's Focus:**
1. {Priority 1}
2. {Priority 2}
3. {Priority 3}

**Alerts:**
- {Alert if any}

**Progress ({Month}):**
- {Goal 1}: X/Y
- {Goal 2}: X/Y

How can I help today?
```

**Result**: User knows what to expect.

### Error Philosophy

#### Validation at Setup

From `setup.sh`:
```bash
# Check for prerequisites
if ! command_exists git; then
    print_color "$RED" "Git is required but not installed."
    print_color "$RED" "Please install git and run this script again."
    exit 1
fi
```

**Pattern**: Fail fast with actionable error message.

#### Graceful Degradation

From `/sync`:
```markdown
If this file doesn't exist, tell the user:
> "I can't find your template source. This usually means you set up 
  MARVIN manually. Would you like to tell me where your template 
  folder is?"
```

**Pattern**: Explain what's wrong + offer fix.

#### Confirmation for Destructive Actions

From integration setup scripts:
```bash
claude mcp remove your-integration 2>/dev/null || true
```

**Pattern**: Remove silently (don't fail if doesn't exist), then add cleanly.

### Output Structure

#### Standardized Help System

From `/help`:
```markdown
## Slash Commands
| Command   | What It Does                        |
|-----------|-------------------------------------|
| /start   | Start a session with a briefing     |
| /end      | End session and save everything     |
```

**Pattern**: Table format for scannable reference.

#### Concise Confirmations

From `/update`:
```markdown
One line: "Checkpointed: {brief description}"

No summary. No "next actions" list. Just confirm the save.
```

**Pattern**: Minimal ceremony for frequent operations.

#### Structured Briefings

From `start` skill:
```markdown
Good morning! It's {Day}, {Date}.

**Today's Focus:**
[Exactly 3 priorities]

**Alerts:**
[Only if present]

**Progress ({Month}):**
[Goal tracking]

How can I help today?
```

**Pattern**: Fixed structure, variable content.

---

## Configuration Management

### Defaults Philosophy

#### User-Centric Defaults

From `setup.sh`:
```bash
DEFAULT_WORKSPACE="$HOME/start"
```

**Rationale**: Short, memorable path. Not hidden directory (`.marvin` would be invisible to new users).

#### Sensible Scope Defaults

From integration setup pattern:
```bash
echo "Where should this integration be available?"
echo "  1) All projects (user-scoped)"
echo "  2) This project only (project-scoped)"
SCOPE_CHOICE=${SCOPE_CHOICE:-1}  # Default to user-scoped
```

**Pattern**: Default to convenience (user-scoped), allow override.

#### Personality Defaults

From `setup.sh`:
```bash
case $PERSONALITY_CHOICE in
    1) PERSONALITY="professional" ;;
    3) PERSONALITY="sarcastic" ;;
    *) PERSONALITY="casual" ;;  # Default
esac
```

**Rationale**: Casual is the safest middle ground.

### Override Patterns

#### Environment Variable Precedence

From `google-workspace/setup.sh`:
```bash
if [ -z "$GOOGLE_OAUTH_CLIENT_ID" ]; then
    read -p "Client ID: " GOOGLE_CLIENT_ID
else
    GOOGLE_CLIENT_ID="$GOOGLE_OAUTH_CLIENT_ID"
fi
```

**Pattern**: Check env var first, prompt only if missing.

#### File-Based Overrides

User can edit `CLAUDE.md` anytime to change:
- Personality
- Goals
- Communication preferences

Changes take effect next `/start`.

#### Skill Customization

Users can:
1. Edit copied skills in workspace
2. `/sync` won't overwrite (only adds new)
3. Create custom skills via `skill-creator` skill

### Validation Strategy

#### Setup-Time Validation

From `setup.sh`:
```bash
if [[ -z "$USER_NAME" ]]; then
    print_color "$RED" "Name is required."
    exit 1
fi
```

**Pattern**: Required fields must be present before proceeding.

#### Integration Validation

From integration setup README requirements:
```markdown
**Danger Zone** (Required Section)

| Action | Risk Level | Who's Affected |
|--------|------------|----------------|
| Send emails | High | Recipients see it immediately |
```

**Pattern**: Force integration authors to document risk.

#### Runtime Validation

From `/sync`:
```markdown
### 1. Find the Template
Read `.marvin-source` to get the path to the template directory

If this file doesn't exist, tell the user:
> "I can't find your template source..."
```

**Pattern**: Validate assumptions, provide context on failure.

---

## Reproducibility

### Deterministic Behavior

#### Given Same State, Same Behavior

**Input state**:
- `CLAUDE.md` (user profile)
- `state/current.md` (priorities)
- `state/goals.md` (goals)
- `sessions/{TODAY}.md` (session history)

**Workflow**: `/start`

**Output**: Identical briefing format, same file read order, same data presentation.

**Why it works**:
1. Commands are files (not context-dependent)
2. File read order is specified
3. Output templates are fixed
4. Date comes from `date +%Y-%m-%d` (deterministic for a given day)

#### Randomness Control

**No randomness in core workflows**. All variation comes from:
- User data (goals, priorities)
- Date (deterministic per day)
- Session history (deterministic accumulation)

### Time-Dependent Operations

#### Date Handling

All date operations use:
```bash
date +%Y-%m-%d
```

**Stored as**: `TODAY` variable in workflow.

**Used for**:
- Session file naming (`sessions/{TODAY}.md`)
- Briefing display
- Timestamps in state files

#### Session Resumption

From `/start`:
```
If resuming a session (today's log exists), acknowledge what was 
already covered.
```

**Pattern**: Time-aware (same day = resume, new day = fresh start), but deterministic given the date.

---

## Functional Extensions

### Voice/Audio Capabilities

**Not present** in the analyzed codebase. Marvin is text-only via Claude Code.

### Integration Patterns

#### MCP-Based Extensions

All integrations use **MCP (Model Context Protocol)** servers:

```bash
claude mcp add google-workspace -s user \
    --env GOOGLE_OAUTH_CLIENT_ID="$CLIENT_ID" \
    -- uvx workspace-mcp --tools gmail drive calendar
```

**Pattern**:
1. Environment variables for secrets
2. Scope selection (user/project)
3. Tool selection (explicit list)

#### Standardized Setup Scripts

All integration setup scripts follow the **same structure**:

```bash
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Integration Name Setup${NC}"
echo -e "${BLUE}======================================${NC}"

# Prerequisites check
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installed${NC}"
else
    echo -e "${RED}✗ Claude Code not found${NC}"
    exit 1
fi

# Scope selection
echo "Where should this integration be available?"
echo "  1) All projects (user-scoped)"
echo "  2) This project only (project-scoped)"
read -r SCOPE_CHOICE
[[ "$SCOPE_CHOICE" == "1" ]] && SCOPE_FLAG="-s user" || SCOPE_FLAG=""

# Remove existing
claude mcp remove integration-name 2>/dev/null || true

# Add new
claude mcp add integration-name $SCOPE_FLAG ...

# Success message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Try: \"example command\""
```

**Result**: All integrations feel the same during setup.

#### Integration Documentation Standard

Required sections in integration README:
1. **What It Does** (bullet list)
2. **Who It's For** (target audience)
3. **Prerequisites** (accounts, permissions)
4. **Setup** (command to run)
5. **Try It** (example commands)
6. **Danger Zone** (risk table) ← **MANDATORY**
7. **Troubleshooting** (common issues)

**Danger Zone table**:
```markdown
| Action | Risk Level | Who's Affected |
|--------|------------|----------------|
| Send emails | High | Recipients see it immediately |
| Delete files | High | Data loss may be permanent |
| Read messages | Low | No external impact |
```

**Pattern**: Force transparency about destructive actions.

### Notification/Alert Mechanisms

#### Proactive Skills

From `content-shipped` skill:
```yaml
metadata:
  proactive: true
```

Skills with `proactive: true` watch conversation for trigger phrases:
- "I shipped..."
- "I published..."

**Pattern**: Automatic detection without explicit invocation.

#### Follow-Up Tracking

From `start` skill:
```markdown
### Step 5: Check Follow-ups
Review `state/current.md` for any follow-up items:
- Surface any items with review date ≤ TODAY
- Remind user of upcoming follow-ups within 3 days
```

**Pattern**: Date-based reminders surfaced in daily briefing.

#### Content Pacing Alerts

From `start` skill:
```markdown
### Step 6: Surface Proactive Alerts
- Content pacing status (if behind)
- Any deadlines approaching
```

**Pattern**: Compare progress to goals, alert if off-pace.

### Self-Directed Features

#### Skill Creator

The `skill-creator` skill enables **self-modification**:

Trigger phrases:
- "Give yourself the ability to..."
- "Create a skill for..."

**Process**:
1. Understand requirement
2. Design skill structure
3. Create `skills/{name}/SKILL.md` with frontmatter
4. Add to skill index in `CLAUDE.md`

**Result**: Marvin can extend its own capabilities via conversation.

#### Template Sync

The `/sync` command enables **self-updating**:

**Process**:
1. Read `.marvin-source` (template location)
2. Compare template commands/skills with workspace
3. Copy NEW items only (never overwrites user customizations)

**Result**: Marvin can pull updates without human intervention.

---

## Lessons for Jarvis

### Workflow Patterns to Adopt

| Pattern | Description | Jarvis Application |
|---------|-------------|-------------------|
| **Workspace Separation** | Template code separate from user data | Create `/Jarvis/jarvis-template/` for AIfred baseline, `/Jarvis/workspace/` for Aircannon's state |
| **Date-Based Session Files** | `sessions/YYYY-MM-DD.md` | Replace current `session-state.md` with dated files for history |
| **File-Read Protocol** | Ordered list of files to load on startup | Codify AC-01 launch sequence as explicit file list |
| **YAML Frontmatter Skills** | Skills declare metadata for behavior validation | Add frontmatter to `.claude/skills/` for proactive detection |
| **Command Files** | Slash commands as markdown files, not context | Move commands to `.claude/commands/` as files |
| **Template Sync Pattern** | `/sync` pulls updates without overwriting state | Create `.jarvis-source` pointer for safe AIfred updates |
| **Setup Script Standardization** | All integrations follow same setup pattern | Standardize `.claude/hooks/` installation scripts |
| **Integration Risk Documentation** | Mandatory "Danger Zone" section | Add risk tables to all autonomous components |

### Documentation Standards

**How Jarvis should document**:

1. **Session Logs**: Adopt dated session files (`sessions/2026-02-05.md`)
   - Current: `.claude/context/session-state.md` (single file)
   - Proposed: `.claude/sessions/YYYY-MM-DD.md` (historical record)

2. **State Schema**: Enforce structured state files
   - Add "Last updated" timestamps
   - Mandatory sections (Active Priorities, Open Threads, Recent Context)
   - Table format for goal tracking

3. **Skill Documentation**: Add YAML frontmatter to all skills
   ```yaml
   ---
   name: session-management
   description: |
     Session lifecycle guidance
   metadata:
     user-invocable: true
     slash-command: /end-session
     proactive: false
   ---
   ```

4. **Command Documentation**: Move commands to `.claude/commands/` as markdown
   - Current: Commands in `CLAUDE.md` (mixed with other content)
   - Proposed: `.claude/commands/end-session.md` (dedicated files)

### State Management Improvements

**Concrete changes for Jarvis consistency**:

1. **Create `.jarvis-source` File**
   ```bash
   echo "/Users/aircannon/Claude/AIfred" > /Users/aircannon/Claude/Jarvis/.jarvis-source
   ```
   - Points to AIfred baseline (commit `2ea4e8b`)
   - Enables safe sync of read-only updates

2. **Adopt Dated Session Files**
   ```bash
   mkdir -p .claude/sessions
   # On AC-01: create sessions/$(date +%Y-%m-%d).md
   # On AC-09: append to sessions/$(date +%Y-%m-%d).md
   ```

3. **Structured State Files**
   ```markdown
   # .claude/context/current-priorities.md
   
   Last updated: 2026-02-05T14:30:00Z
   
   ## Active Priorities
   1. JICM stability (v5.4.2 validation)
   2. Project Aion experimentation
   
   ## Open Threads
   - MTG card sales automation (blocked on Scryfall API research)
   
   ## Recent Context
   - Fixed bash 3.2 `set -e` bug in watcher
   ```

4. **Migration Script** (like `migrate.sh`)
   ```bash
   .claude/scripts/migrate-to-dated-sessions.sh
   # Convert session-state.md → sessions/{dates}.md
   ```

### Command Design Principles

**How Jarvis commands should behave**:

1. **File-Based Commands** (not in-context)
   - Create `.claude/commands/end-session.md`
   - Create `.claude/commands/checkpoint.md`
   - Create `.claude/commands/tooling-health.md`

2. **Explicit Bash Commands** (not "get the date")
   ```markdown
   ### 1. Get Current Date
   Run `date +%Y-%m-%d` and store as TODAY.
   ```

3. **Fixed Output Templates**
   ```markdown
   ## Output Format
   
   Session saved: {TODAY}
   - Topics: {list}
   - Open threads: {count}
   
   See you next time!
   ```

4. **Ordered File Operations**
   ```markdown
   ### 2. Load Context (read in order)
   1. `.claude/context/session-state.md`
   2. `.claude/context/current-priorities.md`
   3. `.claude/sessions/{TODAY}.md` (if exists)
   ```

5. **Validation at Entry**
   ```markdown
   ### 1. Verify Prerequisites
   Check that `.jarvis-source` exists. If not:
   > "Cannot sync: .jarvis-source not found. Run /setup first."
   ```

6. **Graceful Degradation**
   ```markdown
   ### 3. Handle Missing Files
   If `sessions/{TODAY}.md` doesn't exist:
   - Read most recent session file
   - Note: "Resuming from {LAST_DATE} session"
   ```

---

## References

### Key Files Demonstrating Patterns

**Workspace Architecture**:
- `README.md` — Explains dual-directory concept
- `.marvin/setup.sh` — Creates workspace separation
- `.marvin/migrate.sh` — Preserves state during updates

**Command Consistency**:
- `.claude/commands/start.md` — Fixed startup protocol
- `.claude/commands/end.md` — Structured session close
- `.claude/commands/update.md` — Minimal checkpoint pattern
- `.claude/commands/sync.md` — Template update workflow

**Skill System**:
- `skills/_template/SKILL.md` — Skill structure template
- `skills/start/SKILL.md` — Session start with frontmatter
- `skills/content-shipped/SKILL.md` — Proactive detection example
- `skills/skill-creator/SKILL.md` — Self-modification pattern

**State Management**:
- `state/current.md` — Priority tracking schema
- `state/goals.md` — Goal tracking with table
- `content/log.md` — Structured content logging

**Integration Patterns**:
- `.marvin/integrations/README.md` — Standardization requirements
- `.marvin/integrations/google-workspace/setup.sh` — Standard setup pattern
- `.marvin/integrations/google-workspace/README.md` — Risk documentation

---

## Sources

1. [GitHub - SterlingChin/marvin-template](https://github.com/SterlingChin/marvin-template)
2. [Marvin - AI Agent Store](https://aiagentstore.ai/ai-agent/marvin)
3. [HeyMarvin AI - Customer Feedback Repository](https://heymarvin.com/)

---

*Research conducted by: Jarvis (Deep Research Agent)*  
*Report generated: 2026-02-05*  
*Saved to: `.claude/reports/research/marvin-design-philosophy-2026-02-05.md`*

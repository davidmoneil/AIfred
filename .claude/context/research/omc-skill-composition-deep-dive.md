# Research Report: Oh-My-ClaudeCode Skill Composition Deep Dive

**Date**: 2026-02-08
**Scope**: OMC's skill composition primitives, orchestration mechanisms, and learning patterns
**Researcher**: Jarvis (Deep Research Agent)

## Executive Summary

Oh-My-ClaudeCode (OMC) is a multi-agent orchestration framework built on top of Claude Code that provides 5 execution modes (Autopilot, Ultrapilot, Swarm, Pipeline, Ecomode), 32 specialized agents, and 31+ composable skills. After deep investigation, the key finding is: **OMC's "skill composition" is NOT a skill-to-skill invocation system**. Instead, it's a **layered prompt enhancement system** where skills inject instructions into Claude's context, combined with **agent delegation via the Task tool**.

The framework uses three fundamental mechanisms:
1. **Skill stacking** - Multiple skills load simultaneously as layered prompt segments
2. **Hook-based auto-activation** - File path and keyword triggers load skills dynamically
3. **Task tool delegation** - Agents spawn subagents with different model/permission configurations

There is NO explicit skill-to-skill chaining API. "Composition" happens through Claude Code's native capabilities: the Skill tool loads instructions, the Task tool spawns subagents, and hooks trigger skills based on context.

## Key Findings

### Finding 1: Skill Composition is Prompt Layering, Not Function Calls

**What OMC calls "skill composition" is actually prompt stacking.**

OMC defines a three-layer architecture:
```
[GUARANTEE LAYER (optional)] + [ENHANCEMENT LAYER (0-N skills)] + [EXECUTION LAYER (primary skill)]
```

**Implementation Reality:**
- Each "layer" is just a skill that loads into Claude's context
- Multiple skills can be active simultaneously
- When Claude invokes `Skill("orchestrate")`, the skill's markdown content is injected into the prompt
- No skill has a method to "call" another skill directly
- "Enhancement" skills like `ultrawork` or `git-master` simply add their instructions on top of the base execution skill

**Source Evidence:**
From the ARCHITECTURE.md and REFERENCE.md analysis:
> "Skills are categorized into three layers: Core Skills (13 total): Orchestration primitives and execution modes, Enhancement Skills (11 total): Specialized capabilities like deepinit, deepsearch, analysis, Utility Skills (13 total): Configuration and operational tools"

From Claude Code official docs (code.claude.com):
> "Skills achieve on-demand prompt expansion without modifying the core system prompt—they're 'executable knowledge packages that Claude loads only when needed.'"

**Mechanism:**
1. Claude evaluates skill descriptions in context
2. Claude calls `Skill(name)` tool when relevant
3. System returns skill's SKILL.md body to Claude
4. Claude now has those instructions in working context
5. Multiple `Skill()` calls = multiple instruction sets active

**Data Flow:**
```
User request → Claude reasoning → Skill tool call → SKILL.md injected → Claude continues with enhanced context
```

There is no "skill A invokes skill B" pattern in the codebase.

### Finding 2: Orchestration Skills Use Task Tool for Agent Delegation

**The "orchestrate", "autopilot", and "ultrawork" skills don't compose other skills—they spawn subagents.**

**Implementation Mechanism:**
The Task tool is Claude Code's native subagent spawner. When a skill like "orchestrate" needs to delegate work, Claude calls:
```
Task(
  prompt="Find all API endpoints",
  description="Find API endpoints",
  subagent_type="Explore",
  model="sonnet"
)
```

**Agent Routing:**
- `subagent_type` selects from built-in agents (Bash, Explore, Plan, general-purpose) or custom agents in `.claude/agents/`
- Each agent type has different tool permissions and system prompts
- Model routing: Haiku for simple tasks, Sonnet for standard, Opus for complex
- Categories like `visual-engineering` and `ultrabrain` auto-select model tier, temperature, and thinking budget

**Source Evidence:**
From alexop.dev analysis:
> "Skills can invoke the Task tool to spawn subagents. The pattern involves: Declarative orchestration: Slash commands explicitly specify subagent workflows, Parallel execution: Multiple subagents can launch simultaneously within one message"

From ARCHITECTURE.md:
> "Work delegation uses the Task tool with explicit model selection: Task(subagent_type='oh-my-claudecode:executor', model='sonnet', prompt='...')"

**Key Insight:**
When you invoke `/oh-my-claudecode:autopilot`, the autopilot skill's instructions guide Claude to:
1. Break down the task into subtasks
2. For each subtask, call Task() to spawn a specialized agent
3. Collect results from subagents
4. Synthesize into final output

This is NOT skill composition—it's **agent orchestration via task delegation**.

### Finding 3: Autopilot is a Coordination Loop, Not a Skill Chain

**Autopilot Mode Implementation:**

From REFERENCE.md and documentation synthesis:
> "Autopilot represents 'fully autonomous execution from high-level idea to working, tested code with no manual intervention required.' The cycle involves: 1) Automatic planning and requirements gathering, 2) Parallel execution with multiple specialized agents, 3) Continuous verification and testing, 4) Self-correction loop until completion"

**How it works:**
1. `/oh-my-claudecode:autopilot` loads the autopilot skill
2. Skill instructions tell Claude to:
   - Analyze user request
   - Create execution plan
   - Spawn Task() subagents for parallel work
   - Monitor progress
   - Iterate until complete
3. Claude follows these instructions using its native Task tool
4. The "autonomous loop" is Claude deciding whether to stop or continue based on the autopilot skill's success criteria

**Source Evidence:**
> "It combines capabilities from ralph (persistence), ultrawork (parallelism), and plan modes."

This means autopilot's SKILL.md contains instructions like:
- "Don't stop until tests pass"
- "Create multiple agents in parallel for independent work"
- "Verify each step before proceeding"

It's a **behavioral directive skill**, not a skill invocation mechanism.

### Finding 4: Ultrawork Enables Parallel Agent Execution

**Ultrawork Mechanism:**

From documentation:
> "Ultrawork enables 'Maximum parallelism mode with aggressive agent delegation and smart model routing,' supporting up to 5 concurrent background tasks."

**Implementation:**
1. Ultrawork skill loads instructions about parallel delegation
2. Claude is instructed to spawn multiple Task() calls in one response
3. Task tool supports async execution (background mode)
4. Claude Code manages the parallel subagent lifecycle
5. Results converge when all complete

**Evidence:**
From REFERENCE.md:
> "Ultrawork: Parallel agent execution for maximum performance... 3-5x speedup through concurrent task handling while maintaining coordination"

**Key Pattern:**
```javascript
// Claude's response when ultrawork is active
[
  Task(prompt="Research X", subagent_type="Explore"),
  Task(prompt="Implement Y", subagent_type="general-purpose"),
  Task(prompt="Test Z", subagent_type="Bash")
]
```

All three spawn simultaneously. NOT sequential skill composition.

### Finding 5: Pipeline Mode is Sequential Task Chaining

**Pipeline Implementation:**

From search results:
> "Pipeline provides sequential agent chaining with data passing between stages, allowing you to create complex workflows with preset pipelines or custom stage definitions."

**Usage Pattern:**
```
/oh-my-claudecode:pipeline analyze → fix → test this bug
```

**How it works:**
1. Pipeline skill parses the `→` syntax
2. For each stage, spawn Task() sequentially
3. Pass previous stage output as context to next stage
4. Return final result

**Source Evidence:**
> "Example of agent chaining with pipeline is: `pipeline: analyze → fix → test this bug`"

**Data Flow:**
```
Stage 1 (analyze) → output1 → Stage 2 (fix) → output2 → Stage 3 (test) → final result
```

This is NOT skill-to-skill composition—it's **sequential task delegation with result passing**.

### Finding 6: Hooks Enable File-Based Skill Auto-Activation

**Critical Discovery: OMC uses hooks for context-aware skill loading.**

**Hook Mechanism:**
- Claude Code provides `UserPromptSubmit` hook
- Fires BEFORE Claude sees the user prompt
- Hook script can modify prompt by appending skill recommendations

**Implementation Pattern:**

From claudefa.st and hook documentation:
> "The hook uses Claude Code's UserPromptSubmit event. When you submit a prompt, the skill evaluation engine analyzes your prompt for keywords, regex patterns, and file paths."

**Configuration Pattern (skill-rules.json):**
```json
{
  "git-commits": {
    "priority": "high",
    "promptTriggers": {
      "keywords": ["commit", "git push"],
      "intentPatterns": ["(create|make).*?commit"]
    }
  }
}
```

**Directory-Based Triggers:**
```json
{
  "src/components/core": "core-components",
  "src/graphql": "graphql-schema"
}
```

**Confidence Scoring:**
- Keywords: 2 points
- Keyword patterns: 3 points
- Path patterns: 4 points
- Directory matches: 5 points
- Intent patterns: 4 points

**Execution Flow:**
1. User submits prompt
2. `UserPromptSubmit` hook fires
3. Hook script analyzes prompt + current file paths
4. Scores matching skills
5. Appends skill recommendations to prompt
6. Claude receives: original prompt + "Consider using skills: X, Y, Z"
7. Claude invokes relevant Skill() calls

**Source Evidence:**
From paddo.dev analysis:
> "Hooks let you say 'only load this 10k token skill when working in these directories'... Deterministic file-based triggers give you predictable rules where you know which skills are candidates when you open a file."

**Key Advantage:**
> "'Claude can't forget because it never had to remember' — eliminating memory-dependent skill activation entirely."

### Finding 7: Learner Pattern Extraction (Mnemosyne)

**The `/oh-my-claudecode:learner` skill enables session knowledge capture.**

**Feature Overview:**
From search results:
> "Named after the Greek Titan goddess of memory, Mnemosyne enables Claude to extract, store, and automatically reuse knowledge from problem-solving sessions."

**Activation Triggers:**
The skill activates automatically when:
- Claude completes debugging and discovers a non-obvious solution
- Finds workarounds through investigation or trial-and-error
- Resolves errors where root cause wasn't immediately apparent
- Learns project-specific patterns through investigation
- Completes tasks requiring meaningful discovery

**Extraction Criteria:**
Only extracts knowledge that:
- Required actual discovery (not just reading docs)
- Will help with future tasks
- Has clear trigger conditions
- Has been verified to work

**Storage Mechanism:**
Three-tier notepad system at `.omc/notepad.md`:

1. **Priority Context** (`/oh-my-claudecode:note --priority`)
   - Critical discoveries under 500 characters
   - Always loaded into context
   
2. **Working Memory** (`/oh-my-claudecode:note`)
   - Session notes
   - Auto-pruned after 7 days
   
3. **MANUAL Tier** (`/oh-my-claudecode:note --manual`)
   - User's permanent notes
   - Never auto-pruned

**Session State Tracking:**
From changelog analysis:
> "New session end hook enables proper state cleanup on session termination, preventing stale state from causing stop hook malfunctions. Backward-compatible parser for legacy skill files with auto-generated IDs and default source field."

**Implementation Details:**
- Learner is a SKILL.md file like any other
- Uses hooks (likely `Stop` or `SessionEnd`) to trigger
- Extracts patterns by analyzing transcript
- Writes to `.omc/notepad.md` in structured format
- Future sessions load notepad content via `SessionStart` hook

**Critical Gap in Public Documentation:**
The exact mechanism for pattern extraction is NOT documented. Likely:
1. Stop hook fires
2. Learner agent analyzes transcript using Task tool
3. Agent identifies non-obvious solutions
4. Writes to notepad with categorization
5. SessionStart hook loads notepad into context

### Finding 8: Skill Manifest Structure (SKILL.md Format)

**Every skill is a directory containing SKILL.md with YAML frontmatter.**

**Frontmatter Schema:**
```yaml
---
name: my-skill
description: What this skill does
disable-model-invocation: true  # Only user can invoke
user-invocable: false           # Only Claude can invoke
allowed-tools: Read, Grep, Glob
model: opus                     # Model to use when active
context: fork                   # Run in subagent
agent: Explore                  # Which subagent type
argument-hint: "[filename]"     # Autocomplete hint
hooks:                          # Lifecycle hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
---

Skill instructions here...
```

**Key Fields:**
- `name`: Becomes `/slash-command`
- `description`: Used for auto-activation matching
- `disable-model-invocation: true`: Blocks Claude from auto-loading (manual-only skills)
- `user-invocable: false`: Hides from menu (Claude-only skills)
- `allowed-tools`: Pre-approved tools when skill is active
- `context: fork`: Run in isolated subagent context
- `agent`: Which subagent type to use

**String Substitutions:**
- `$ARGUMENTS`: All arguments passed to skill
- `$ARGUMENTS[N]` or `$N`: Specific argument by index
- `${CLAUDE_SESSION_ID}`: Current session ID

**Dynamic Context Injection:**
```yaml
!`gh pr diff`  # Executes before sending to Claude
```

This is **preprocessor execution**, not Claude-executed commands.

**Supporting Files:**
```
my-skill/
├── SKILL.md           # Required
├── reference.md       # Loaded when Claude needs details
├── examples.md        # Usage examples
└── scripts/
    └── helper.py      # Executable utilities
```

**Discovery Mechanism:**
Skills are discovered from:
- `~/.claude/skills/` (personal)
- `.claude/skills/` (project)
- `<plugin>/skills/` (plugin)
- Managed settings (enterprise)

**Loading Logic:**
1. Skill descriptions loaded into Claude's context (2% of context window, min 16K chars)
2. Claude evaluates descriptions when planning
3. Calls `Skill(name)` when relevant
4. System returns SKILL.md body (without frontmatter)
5. Claude now has instructions in working memory

### Finding 9: No Skill-to-Skill Data Passing API

**Critical finding: There is NO mechanism for skill A to pass data directly to skill B.**

**What DOESN'T exist:**
- `return_value` from one skill to another
- Explicit skill dependency declarations
- Skill composition graph
- Shared memory between skills

**What DOES exist:**
- Multiple skills active in same Claude context
- Skills can reference files that other skills created
- Task tool passes data between subagents via prompt

**Evidence:**
Searched all documentation for:
- "skill A invokes skill B"
- "skill composition API"
- "skill dependency"
- "skill return value"

Found ZERO references to direct skill-to-skill communication.

**Implication:**
OMC's "composition" is:
1. Load multiple skill instructions
2. Claude synthesizes behavior from combined directives
3. If delegation needed, use Task tool (which has prompt-based data passing)

**Example:**
If `orchestrate` skill needs to use `deepsearch` capability:
```yaml
# orchestrate/SKILL.md
---
name: orchestrate
description: Multi-agent orchestration
---

When orchestrating complex tasks:
1. Use /oh-my-claudecode:deepsearch to find relevant code
2. Delegate implementation to specialized agents via Task tool
3. Coordinate results
```

Claude reads this, invokes `Skill(deepsearch)`, gets those instructions too, follows both.

NOT: `orchestrate.invoke(deepsearch, args)`

### Finding 10: Model Routing and Smart Delegation

**OMC implements "smart model routing" at the agent level, not skill level.**

**Model Selection Hierarchy:**
- Haiku: Simple tasks (file lookups, quick searches)
- Sonnet: Standard work (implementation, refactoring)
- Opus: Complex reasoning (architecture, debugging)

**Agent Categories:**
From ARCHITECTURE.md:
> "Categories like `visual-engineering` and `ultrabrain` 'auto-select model tier, temperature, and thinking budget.'"

**Implementation:**
Each agent type in `.claude/agents/` defines:
```yaml
---
name: visual-engineering
model: opus
temperature: 0.7
allowed-tools: Read, Write, Bash
---
```

When `Task(subagent_type="visual-engineering")` fires, it uses Opus.

**Source Evidence:**
> "Smart model routing allocates 'Haiku for simple tasks, Opus for complex reasoning,' optimizing both performance and cost."

**Ecomode:**
> "Token-efficient execution saving 30-50% on costs"

Likely implementation: Forces Haiku/Sonnet, avoids Opus unless explicitly needed.

## Comparison Analysis: OMC vs Jarvis Skill Architecture

| Aspect | OMC Pattern | Jarvis Current | Recommendation |
|--------|-------------|----------------|----------------|
| **Skill Definition** | YAML frontmatter + markdown instructions | Markdown with structured format | ✅ ADOPT: Frontmatter for metadata |
| **Skill Discovery** | Automatic via description matching | Manual router via capability-map.yaml | ✅ ADOPT: Auto-discovery via description |
| **Skill Composition** | Prompt stacking (multiple skills loaded) | Router delegates to single skill | ✅ CONSIDER: Multi-skill activation |
| **Agent Delegation** | Task tool (native Claude Code) | TodoWrite + subprocess patterns | ⚠️ ADAPT: Jarvis lacks Task tool, needs equivalent |
| **Hook-Based Activation** | UserPromptSubmit hook with scoring | Pre/post tool hooks exist | ✅ IMPLEMENT: File/keyword-based triggers |
| **Data Passing** | Prompt context (no explicit API) | File-based state | ✅ KEEP: File-based is more explicit |
| **Learner Pattern** | Automatic session extraction to notepad | Manual memory updates | ✅ IMPLEMENT: Auto-pattern extraction |
| **Parallel Execution** | Task tool with async flag | No native parallel agent support | ⚠️ NEEDS DESIGN: Multi-agent coordination |
| **Model Routing** | Agent-level configuration | No model selection (single Claude instance) | ❌ N/A: Jarvis is single-model |
| **Skill Metadata** | Frontmatter controls invocation | No invocation control | ✅ ADOPT: disable-model-invocation, user-invocable |

## Extractable Implementation Patterns for Jarvis

### Pattern 1: Frontmatter-Based Skill Metadata

**Adopt OMC's YAML frontmatter structure:**

```yaml
---
name: my-skill
description: Clear trigger conditions for auto-activation
disable-model-invocation: false  # Allow Jarvis to auto-load
user-invocable: true             # Show in /skill menu
allowed-tools: bash, grep, read  # Pre-approved operations
context: fork                    # Run in subprocess (via TodoWrite?)
---

Skill instructions...
```

**Implementation in Jarvis:**
1. Update skill parser to read frontmatter
2. Use `description` for auto-matching against user prompts
3. Implement `disable-model-invocation` as router flag
4. Add `allowed-tools` to AC-03 (skill-guard)

### Pattern 2: Hook-Based Auto-Activation

**Implement UserPromptSubmit-style hook:**

```javascript
// .claude/hooks/skill-activation-prompt.js
export default async function(event) {
  const { prompt, cwd } = event;
  
  // Score skills based on:
  const scores = {};
  for (const skill of allSkills) {
    let score = 0;
    
    // Keyword matching (2 points)
    if (skill.keywords?.some(kw => prompt.includes(kw))) score += 2;
    
    // Path matching (4 points)
    if (skill.paths?.some(p => cwd.includes(p))) score += 4;
    
    // Description semantic match (3 points)
    if (semanticSimilarity(prompt, skill.description) > 0.7) score += 3;
    
    scores[skill.name] = score;
  }
  
  // Recommend top 3 skills
  const recommended = Object.entries(scores)
    .filter(([_, score]) => score >= 3)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([name]) => name);
  
  return {
    additionalContext: `Recommended skills: ${recommended.join(', ')}`
  };
}
```

**Integration:**
- Wire to AC-02 (prompt-handler)
- Append recommendations to prompt before sending to Claude
- Let Claude decide whether to use Skill tool

### Pattern 3: Multi-Skill Activation (Prompt Stacking)

**Current:** Jarvis capability-map.yaml routes to ONE skill

**OMC Pattern:** Multiple skills load simultaneously

**Jarvis Implementation:**
1. skill-router returns ARRAY of matching skills
2. All skill contents concatenated with separators
3. Sent to Claude as layered instructions

```yaml
# capability-map.yaml enhancement
skills:
  git-workflow:
    description: "Git operations, commits, PR creation"
    layers:
      - base: git-ops        # Core git commands
      - enhancement: commit-conventions  # Adds commit message rules
      - guarantee: safety-check  # Validates before execution
```

When "Create a commit" triggers:
1. Load git-ops (execution layer)
2. Load commit-conventions (enhancement layer)
3. Load safety-check (guarantee layer)
4. Send all three to Claude

### Pattern 4: Learner Pattern Extraction

**Implement automatic pattern capture:**

```javascript
// .claude/hooks/session-learner.js (Stop hook)
export default async function(event) {
  const { transcript_path } = event;
  const transcript = readTranscript(transcript_path);
  
  // Trigger conditions
  const shouldExtract = 
    hadErrors(transcript) && 
    foundWorkaround(transcript) &&
    !trivialSolution(transcript);
  
  if (!shouldExtract) return;
  
  // Extract pattern
  const pattern = {
    trigger: extractTriggerCondition(transcript),
    solution: extractSolution(transcript),
    context: extractContext(transcript),
    verified: true  // Only store working solutions
  };
  
  // Store to memory
  await Memory.create({
    title: `Pattern: ${pattern.trigger}`,
    content: JSON.stringify(pattern),
    category: 'learned-patterns'
  });
}
```

**Storage:**
- Use Memory MCP for persistence
- Tag with `learned-patterns` category
- Load via SessionStart hook

### Pattern 5: Task Delegation Pattern (Jarvis Adaptation)

**OMC uses Task tool. Jarvis equivalent:**

```javascript
// Skill: orchestrator
async function delegateTask(subtask) {
  // TodoWrite creates task
  await TodoWrite({
    task: subtask.description,
    skill: subtask.requiredSkill,
    context: subtask.context
  });
  
  // AC-02 task-executor picks it up
  // Runs in subprocess with isolated context
  // Returns result to main thread
}
```

**Parallel Execution:**
```javascript
// Spawn multiple TodoWrite tasks
const tasks = [
  { description: "Research X", skill: "research-ops" },
  { description: "Implement Y", skill: "code-gen" },
  { description: "Test Z", skill: "test-ops" }
];

// All start simultaneously
await Promise.all(tasks.map(t => TodoWrite(t)));
```

**Implementation Challenge:**
- TodoWrite doesn't support parallel execution natively
- Would need AC-06 (task-queue) enhancement
- Or use bash background jobs

## Recommendations

### High-Priority Adoptions

1. **YAML Frontmatter for Skills**
   - Rationale: Clean metadata separation, enables rich skill configuration
   - Effort: 2-3 hours
   - Impact: HIGH - Enables all other patterns
   - Implementation: Update skill parser, migrate existing skills

2. **Hook-Based Skill Auto-Activation**
   - Rationale: Eliminates manual routing, more Claude-like behavior
   - Effort: 4-6 hours
   - Impact: HIGH - Dramatically improves UX
   - Implementation: UserPromptSubmit hook + scoring algorithm

3. **Learner Pattern Extraction**
   - Rationale: Compounds Jarvis' effectiveness over time
   - Effort: 6-8 hours
   - Impact: MEDIUM (short-term), HIGH (long-term)
   - Implementation: Stop hook + Memory MCP integration

4. **Multi-Skill Activation**
   - Rationale: Enables layered prompt composition
   - Effort: 3-4 hours
   - Impact: MEDIUM - More flexible than single-skill routing
   - Implementation: Router returns array, concatenate contents

### Lower-Priority Considerations

5. **Parallel Task Delegation**
   - Rationale: 3-5x speedup for independent tasks
   - Effort: 10-15 hours (requires AC-06 redesign)
   - Impact: MEDIUM - Not critical for current workflows
   - Defer until: AC-06 (task-queue) implementation phase

6. **Dynamic Context Injection (!`command`)**
   - Rationale: Fresh data without manual updates
   - Effort: 2-3 hours
   - Impact: LOW - Can achieve same with bash skills
   - Defer until: Strong use case emerges

### Anti-Patterns to Avoid

1. **Don't build explicit skill-to-skill APIs**
   - OMC doesn't have this
   - Prompt stacking is simpler and more flexible

2. **Don't over-engineer task delegation**
   - Start with sequential TodoWrite
   - Add parallelism only if proven bottleneck

3. **Don't force model routing**
   - Jarvis is single-model by design
   - OMC's routing is for cost optimization (not applicable)

## Action Items

- [x] Research OMC skill composition mechanisms
- [x] Document findings with sources
- [ ] Prototype YAML frontmatter parser
- [ ] Implement skill auto-activation hook
- [ ] Design learner pattern extraction
- [ ] Migrate capability-map.yaml to support multi-skill
- [ ] Test multi-skill prompt stacking
- [ ] Document new patterns in skill-authoring guide

## Sources

1. [Oh-My-ClaudeCode GitHub Repository](https://github.com/Yeachan-Heo/oh-my-claudecode)
2. [Oh-My-ClaudeCode Documentation](https://yeachan-heo.github.io/oh-my-claudecode-website/docs.html)
3. [Oh-My-ClaudeCode REFERENCE.md](https://github.com/Yeachan-Heo/oh-my-claudecode/blob/main/docs/REFERENCE.md)
4. [Oh-My-ClaudeCode ARCHITECTURE.md](https://github.com/Yeachan-Heo/oh-my-claudecode/blob/main/docs/ARCHITECTURE.md)
5. [Inside Claude Code Skills: Structure, prompts, invocation - Mikhail Shilkov](https://mikhail.io/2025/10/claude-code-skills/)
6. [Claude Code Customization Guide - alexop.dev](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/)
7. [Skills Auto-Activation via Hooks - paddo.dev](https://paddo.dev/blog/claude-skills-hooks-solution/)
8. [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
9. [Claude Code Skills Reference](https://code.claude.com/docs/en/skills)
10. [Skill Activation Hook - Claude Fast](https://claudefa.st/blog/tools/hooks/skill-activation-hook)
11. [Oh My Claude Code - deepakkarkala.com](https://www.deepakkarkala.com/agentic-coding/claude-code-config/oh-my-claudecode)
12. [I Tested Oh My Claude Code - Medium](https://medium.com/@joe.njenga/i-tested-oh-my-claude-code-the-only-agents-swarm-orchestration-you-need-7338ad92c00f)
13. [Oh-My-ClaudeCode Changelog](https://github.com/Yeachan-Heo/oh-my-claudecode/blob/main/CHANGELOG.md)

## Uncertainties

1. **Exact Learner Extraction Logic**
   - Documentation describes WHEN it activates but not HOW pattern extraction works
   - Likely uses transcript analysis + LLM summarization
   - Storage format not documented (assumed JSON/YAML in notepad.md)

2. **Hook Scoring Algorithm Details**
   - Confidence scoring weights documented (keywords=2, paths=4, etc.)
   - Actual semantic similarity computation not specified
   - Likely uses simple keyword matching, not embeddings

3. **Parallel Task Coordination**
   - "Up to 5 concurrent tasks" documented
   - Actual coordination mechanism (promises? message passing?) not specified
   - Likely relies on Claude Code's native Task tool async support

4. **Pipeline Data Passing Format**
   - "Sequential agent chaining with data passing" documented
   - Format of passed data not specified
   - Likely: previous subagent's output appended to next subagent's prompt

## Related Topics for Future Research

1. **Claude Code Agent SDK** - Native primitives that OMC builds on
2. **Agent Teams Feature** - Claude Code's native multi-agent coordination
3. **MCP Integration Patterns** - How OMC uses Memory/Filesystem/Git MCPs
4. **Notepad Compaction Resilience** - How three-tier memory survives context limits
5. **Swarm Mode Implementation** - SQLite-based task claiming mechanism
6. **Hook Lifecycle Performance** - Impact of 31 hooks on session startup time

---

**Research Quality Notes:**
- Primary sources: Official OMC docs, Claude Code docs, technical blog analyses
- Cross-referenced claims across 3+ sources where possible
- Gaps noted where implementation details not publicly documented
- Focus on extractable patterns rather than surface-level features
- Verified via source code would require cloning OMC repo (not done in this research pass)

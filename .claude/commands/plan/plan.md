---
description: "Guided conversational planning for new designs, system reviews, and feature development"
argument-hint: "[description]"
model: opus
---

# /plan - Structured Planning Command

Start a guided planning session with dynamic question depth. Auto-detects the appropriate mode based on your request.

## Arguments

- `description` (optional): Brief description of what you want to plan
- `--mode=<mode>`: Force a specific mode (new-design, system-review, feature)
- `--depth=<level>`: Set question depth (minimal, auto, comprehensive)

## Execution Flow

### Step 1: Mode Detection

If no `--mode` flag provided:

1. Analyze the description for planning mode signals
2. Suggest the detected mode with confidence level
3. Use AskUserQuestion to confirm:

```
Based on your request, I'm suggesting **[Mode Name]** mode.

This mode is best for: [brief description]

Is this the right approach?
- Yes, proceed with [Mode Name]
- No, use New Design mode
- No, use System Review mode
- No, use Feature Planning mode
```

If `--mode` flag provided, skip detection and use specified mode directly.

### Step 2: Initialize Session

1. Generate session ID: `plan-YYYYMMDD-HHMMSS`
2. Read the question bank: `.claude/skills/structured-planning/templates/question-bank.yaml`
3. Select questions for the detected mode
4. Create planning directory if needed: `.claude/planning/specs/`

### Step 3: Discovery Phase

For each question category (vision, scope, technical, constraints, risks):

1. Ask base questions from the question bank
2. After each answer, analyze for complexity signals:
   - Uncertainty words ("maybe", "not sure", "depends")
   - Multiple stakeholders mentioned
   - Integration requirements
   - Security/compliance mentions
   - Scale concerns

3. If complexity signals detected (score >= 3):
   - Add extended questions for that category
   - Inform user: "I'd like to explore [topic] a bit more based on what you mentioned..."

4. If user says "that's enough detail" or similar, move to next category

5. Between categories, show brief progress:
   ```
   ✓ Vision & Goals - captured
   → Scope & Features - current
   ○ Technical Considerations - next
   ○ Constraints - pending
   ○ Risks - pending
   ```

### Step 4: Draft Specification

1. Generate specification document using the appropriate template:
   - New Design: `templates/new-design-spec.md`
   - System Review: `templates/system-review-spec.md`
   - Feature: `templates/feature-plan-spec.md`

2. Fill placeholders with captured information

3. Present draft summary to user:
   ```
   ## Draft Specification Summary

   **Project**: [name]
   **Mode**: [mode]

   ### Vision
   [summary]

   ### Scope
   - MVP: [features]
   - Out of scope: [items]

   ### Technical Approach
   [summary]

   Does this capture your intent? Any adjustments needed?
   ```

4. If user requests changes:
   - Clarify what needs adjustment
   - Update relevant sections
   - Present revised summary

### Step 5: Save Specification

Once user approves:

1. Generate filename: `YYYY-MM-DD-{slugified-name}.md`
2. Write to `.claude/planning/specs/{filename}`
3. Confirm: "Specification saved to `.claude/planning/specs/{filename}`"

### Step 6: Generate Orchestration

1. Extract phases from specification:
   - MVP features become Phase 1 tasks
   - Phase 2 features become later phase tasks
   - Technical setup becomes foundation tasks

2. Create orchestration YAML:
   ```yaml
   name: "{project-name}"
   created: "YYYY-MM-DD"
   spec_file: ".claude/planning/specs/{spec-filename}"
   planning_mode: "{mode}"
   status: active

   phases:
     - name: "Phase 1: Foundation"
       tasks:
         # Generated from spec
   ```

3. Write to `.claude/orchestration/YYYY-MM-DD-{slug}.yaml`

4. Update specification with orchestration link

### Step 7: Handoff

Present completion summary:

```
## Planning Complete

**Specification**: `.claude/planning/specs/YYYY-MM-DD-{name}.md`
**Orchestration**: `.claude/orchestration/YYYY-MM-DD-{name}.yaml`

### What's Next

Run these commands to execute your plan:

- `/orchestration:status` - See the task breakdown
- `/orchestration:resume` - Start working on tasks
- `/parallel-dev:start {name}` - Run autonomous parallel development

### Planning Session Stats

- Questions asked: X
- Depth escalations: Y
- Categories covered: Z/5
```

## Mode-Specific Behavior

### New Design Mode (`--mode=new-design`)

- Full question set across all 5 categories
- Emphasis on vision, scope, and technical architecture
- Generates complete design specification
- Full orchestration with all phases

### System Review Mode (`--mode=system-review`)

- Focus on current state assessment
- Pain point identification
- Gap analysis
- Generates review findings + improvement plan
- Orchestration organized by improvement priority

### Feature Planning Mode (`--mode=feature`)

- Lighter question set (3 categories)
- Focus on scope and integration
- Generates feature specification
- Smaller orchestration focused on feature implementation

## Depth Levels

### Minimal (`--depth=minimal`)

- Only base questions per category
- No complexity signal detection
- Quick planning for simple tasks

### Auto (`--depth=auto`) - Default

- Base questions always
- Extended questions when complexity detected
- Deep questions for high complexity (score >= 5)

### Comprehensive (`--depth=comprehensive`)

- All questions (base + extended + deep)
- Full exploration regardless of complexity
- Use for strategic or high-stakes planning

## Examples

**Auto-detect mode**:
```
/plan "I want to build a habit tracking application"
```

**Explicit mode**:
```
/plan --mode=new-design "Build authentication system"
/plan --mode=system-review "Review the voice character system"
/plan --mode=feature "Add dark mode to the dashboard"
```

**With depth control**:
```
/plan --depth=minimal "Quick feature for logging"
/plan --depth=comprehensive "Mission-critical payment system"
```

## Related Commands

- `/plan:new` - Jump directly to New Design mode
- `/plan:review` - Jump directly to System Review mode
- `/plan:feature` - Jump directly to Feature Planning mode
- `/orchestration:status` - View generated orchestration
- `/orchestration:resume` - Continue with implementation

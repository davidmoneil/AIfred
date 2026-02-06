# Prompt Enhancement Pattern

**Status**: Implemented (Phase 1 + Phase 2)
**Created**: 2026-01-21
**Updated**: 2026-01-21
**Purpose**: Automatically enhance user prompts with contextual guidance

---

## Overview

The Prompt Enhancement Pattern uses Claude Code hooks to detect common prompt patterns and inject relevant guidance, ensuring Claude uses optimal tools and approaches.

**Key Insight**: Hooks cannot rewrite prompts, but can:
1. Add contextual guidance before Claude processes the prompt
2. Intercept suboptimal tool calls and redirect to better alternatives

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROMPT ENHANCEMENT FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│  USER INPUT                                                      │
│  "Go to the definition of auditLogger"                          │
│                              ↓                                   │
├─────────────────────────────────────────────────────────────────┤
│  HOOK: UserPromptSubmit (prompt-enhancer.js)                    │
│  1. Pattern matching against enhancement rules                   │
│  2. If match: inject additionalContext                          │
│     → "For code navigation, use LSP tool (50x faster)..."       │
│                              ↓                                   │
├─────────────────────────────────────────────────────────────────┤
│  CLAUDE PROCESSING                                               │
│  Sees original prompt + injected context                        │
│  Chooses LSP tool based on guidance                             │
│                              ↓                                   │
├─────────────────────────────────────────────────────────────────┤
│  HOOK: PreToolUse (tool-redirector.js) [BACKUP]                 │
│  If Claude still chose Grep/Search for navigation:              │
│  → Block with redirect message to LSP                           │
│                              ↓                                   │
├─────────────────────────────────────────────────────────────────┤
│  TOOL EXECUTION                                                  │
│  LSP(operation: "goToDefinition", ...)                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Enhancement Rules

### Rule Structure

```yaml
rules:
  - id: lsp-navigation
    patterns:
      - "go\\s+to\\s+(definition|implementation)"
      - "find\\s+(references?|usages?)"
      - "where.*defined"
      - "list.*symbols"
    context: |
      For code navigation queries, use the LSP tool instead of Search/Grep.
      LSP provides semantic understanding (50ms vs seconds).
      Operations: goToDefinition, findReferences, documentSymbol, hover
    priority: high

  - id: docker-mcp
    patterns:
      - "docker\\s+(ps|logs|inspect|start|stop)"
      - "container\\s+(status|list)"
    context: |
      For Docker operations, use MCP tools (mcp__mcp-gateway__docker)
      instead of Bash commands. MCP provides structured output.
    priority: medium
```

### Initial Rules to Implement

| Rule ID | Trigger Patterns | Enhancement |
|---------|------------------|-------------|
| `lsp-navigation` | "go to definition", "find references", "where defined" | Use LSP tool |
| `docker-mcp` | "docker ps", "container status" | Use MCP docker tool |
| `git-mcp` | "git status", "git log", "git diff" | Use MCP git tools |
| `memory-mcp` | "remember", "store in memory", "save to graph" | Use Memory MCP |

---

## Implementation Plan

### Phase 1: UserPromptSubmit Hook (Soft Guidance)

Create `prompt-enhancer.js` that:
1. Receives user prompt
2. Matches against rule patterns
3. Injects `additionalContext` with guidance
4. Returns enhanced context

**Pros**: Non-blocking, educational, low friction
**Cons**: Claude may still ignore guidance

### Phase 2: PreToolUse Hook (Hard Redirect)

Create `tool-redirector.js` that:
1. Monitors Grep/Search/Bash calls
2. Detects navigation-like or MCP-eligible patterns
3. Blocks suboptimal tool with redirect message
4. Claude retries with recommended tool

**Pros**: Guarantees optimal tool usage
**Cons**: Higher friction, may feel restrictive

### Phase 3: Rule Configuration

Create `enhancement-rules.yaml` for:
- User-configurable rules
- Easy addition of new patterns
- Priority ordering
- Enable/disable per rule

---

## File Structure

```
.claude/
├── hooks/
│   ├── prompt-enhancer.js      # UserPromptSubmit hook
│   └── tool-redirector.js      # PreToolUse hook (optional)
├── config/
│   └── enhancement-rules.yaml  # Rule definitions
└── context/patterns/
    └── prompt-enhancement-pattern.md  # This doc
```

---

## Hook Configuration

```json
// In .claude/settings.json or hooks config
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "node .claude/hooks/prompt-enhancer.js",
        "timeout": 5
      }
    ],
    "PreToolUse": [
      {
        "matcher": {
          "tool_name": ["Grep", "Search", "Bash"]
        },
        "type": "command",
        "command": "node .claude/hooks/tool-redirector.js",
        "timeout": 5
      }
    ]
  }
}
```

---

## Example: prompt-enhancer.js

```javascript
#!/usr/bin/env node

const fs = require('fs');

// Read input from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const prompt = data.prompt || '';

    // Enhancement rules
    const rules = [
      {
        id: 'lsp-navigation',
        patterns: [
          /\bgo\s+to\s+(definition|implementation)/i,
          /\bfind\s+(references?|usages?)/i,
          /\bwhere.*defined\b/i,
          /\blist.*symbols?\b/i,
          /\bdefinition\s+of\b/i
        ],
        context: '📌 LSP Tip: Use the LSP tool for code navigation (goToDefinition, findReferences, documentSymbol). It\'s 50x faster than Search/Grep and semantically accurate.'
      },
      {
        id: 'docker-mcp',
        patterns: [
          /\bdocker\s+(ps|logs|inspect|start|stop|restart)\b/i,
          /\bcontainer\s+(status|list|health)\b/i
        ],
        context: '📌 Docker Tip: Use MCP docker tools (mcp__mcp-gateway__docker) for structured output instead of Bash.'
      }
    ];

    // Find matching rules
    const matchedContexts = [];
    for (const rule of rules) {
      if (rule.patterns.some(p => p.test(prompt))) {
        matchedContexts.push(rule.context);
      }
    }

    // Output result
    const result = {
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        decision: 'allow'
      }
    };

    if (matchedContexts.length > 0) {
      result.hookSpecificOutput.additionalContext = matchedContexts.join('\n\n');
    }

    console.log(JSON.stringify(result));
    process.exit(0);
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
});
```

---

## Success Criteria

1. User types "go to definition of X" → Claude uses LSP
2. User types "docker ps" → Claude uses MCP
3. Rules are configurable without code changes
4. Minimal latency impact (<100ms per hook)
5. Non-disruptive to user experience

---

## Implementation Status

### Phase 2: PreToolUse Hook (Hard Redirect) ✅ Implemented

**File**: `.claude/hooks/lsp-redirector.js`

Intercepts Grep tool calls and blocks navigation queries with a redirect to LSP.

**Detected Patterns**:
- Definition lookups: "definition of X", "where X defined", "go to definition"
- Reference lookups: "references to X", "usages of X", "who calls X"
- Symbol lookups: "find function X", "find class X"
- Implementation lookups: "implementation of X"

**Testing**:
```bash
# Test navigation query (should block)
echo '{"tool_name": "Grep", "tool_input": {"pattern": "definition of X"}}' | node .claude/hooks/lsp-redirector.js

# Test regular search (should allow)
echo '{"tool_name": "Grep", "tool_input": {"pattern": "TODO|FIXME"}}' | node .claude/hooks/lsp-redirector.js
```

### Phase 1: UserPromptSubmit Hook (Soft Guidance) ✅ Implemented

**File**: `.claude/hooks/prompt-enhancer.js`

Injects contextual guidance when user prompts match navigation patterns.

**Detected Patterns**:
- Definition lookups: "go to definition", "where X defined", "find definition"
- Reference lookups: "find usages of", "show me all references", "who calls X"
- Symbol lookups: "list all symbols", "find function X"
- Docker/Git MCP guidance (bonus)

**Testing**:
```bash
# Test navigation query (should inject LSP guidance)
echo '{"prompt": "Go to the definition of main"}' | node .claude/hooks/prompt-enhancer.js

# Test regular query (no injection)
echo '{"prompt": "What is the weather?"}' | node .claude/hooks/prompt-enhancer.js
```

**Output**: `additionalContext` field with LSP usage guidance, injected into Claude's context.

### Phase 3: Rule Configuration - Not Implemented

Deferred - Current hardcoded rules work well for LSP. Will implement if more rules are needed.

---

## Related

- @.claude/hooks/README.md - Hooks documentation
- @.claude/hooks/prompt-enhancer.js - Phase 1: UserPromptSubmit soft guidance
- @.claude/hooks/lsp-redirector.js - Phase 2: PreToolUse hard redirect

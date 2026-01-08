# Batch MCP Validation Pattern

**Created**: 2026-01-08
**Status**: Active
**Related**: mcp-validation-harness.md, context-budget-management.md

---

## Purpose

Validate MCPs in smaller batches to ensure all tools load properly within context token limits (~45K for tool definitions).

---

## The Problem

When all 17 MCPs are active simultaneously:
- Total tool definition tokens exceed context budget
- Some MCPs show "Connected" but tools don't load (Discovery #7)
- Validation cannot confirm all tools are functional

**Solution**: Test MCPs in batches of 6-8, ensuring each batch fits within token limits.

---

## Batch Definitions

### Tier 1 Core (Always Included)

| MCP | Tools | Tokens | Purpose |
|-----|-------|--------|---------|
| memory | 9 | ~1.8K | Knowledge persistence |
| filesystem | 13 | ~2.8K | File operations |
| fetch | 1 | ~0.5K | Web content retrieval |
| git | 12 | ~2.5K | Version control |

**Total**: ~7.6K tokens (always loaded)

### Batch 1: Development

| MCP | Tools | Tokens | Purpose |
|-----|-------|--------|---------|
| github | 20+ | ~5K | Repository operations |
| context7 | 2 | ~2K | Library documentation |
| sequential-thinking | 1 | ~1K | Complex reasoning |
| datetime | 1 | ~1K | Time operations |

**Batch Total**: ~9K + 7.6K core = ~16.6K tokens

### Batch 2: Research

| MCP | Tools | Tokens | Purpose |
|-----|-------|--------|---------|
| brave-search | 2 | ~3K | Web search |
| arxiv | 4 | ~2K | Academic papers |
| perplexity | 4 | ~3K | AI-powered search |
| wikipedia | 2 | ~2K | Encyclopedia |

**Batch Total**: ~10K + 7.6K core = ~17.6K tokens

### Batch 3: Utilities

| MCP | Tools | Tokens | Purpose |
|-----|-------|--------|---------|
| desktop-commander | 30+ | ~8K | System operations |
| chroma | 12 | ~4K | Vector database |
| gptresearcher | 5 | ~3K | Deep research |

**Batch Total**: ~15K + 7.6K core = ~22.6K tokens

### Batch 4: Specialized

| MCP | Tools | Tokens | Purpose |
|-----|-------|--------|---------|
| playwright | 20+ | ~6K | Browser automation |
| lotus-wisdom | 2 | ~2K | Contemplative reasoning |

**Batch Total**: ~8K + 7.6K core = ~15.6K tokens

---

## Validation Workflow

### Step 1: Configure Batch

```bash
# Configure batch N (1-4)
.claude/scripts/mcp-validation-batches.sh 1

# Or manually with disable script
.claude/scripts/disable-mcps.sh github context7 sequential-thinking ...
```

### Step 2: Apply Configuration

Run `/clear` or restart Claude Code session.

### Step 3: Verify Tools Loaded

```
# Check MCP status
claude mcp list

# Verify tools are available by testing each MCP
```

### Step 4: Run Functional Tests

For each MCP in the batch:

1. **Happy Path Test**: Execute primary tool with valid input
2. **Verify Output**: Confirm expected response format
3. **Document Results**: Record in validation log

### Step 5: Record Results

Update `.claude/logs/mcp-validation/batch-N-YYYY-MM-DD.md`

### Step 6: Next Batch

```bash
# Configure next batch
.claude/scripts/mcp-validation-batches.sh 2
```

Then run `/clear` and repeat.

### Step 7: Restore Full Config

```bash
# After all batches validated
.claude/scripts/mcp-validation-batches.sh reset
```

---

## Batch Validation Script

### Location

`.claude/scripts/mcp-validation-batches.sh`

### Commands

| Command | Description |
|---------|-------------|
| `./mcp-validation-batches.sh list` | Show all batch definitions |
| `./mcp-validation-batches.sh 1` | Configure for Batch 1 (Development) |
| `./mcp-validation-batches.sh 2` | Configure for Batch 2 (Research) |
| `./mcp-validation-batches.sh 3` | Configure for Batch 3 (Utilities) |
| `./mcp-validation-batches.sh 4` | Configure for Batch 4 (Specialized) |
| `./mcp-validation-batches.sh reset` | Enable all MCPs |

---

## Functional Test Templates

### Batch 1: Development

```
# github
mcp__github__get_file_contents(owner, repo, path)

# context7
mcp__context7__resolve-library-id(libraryName)

# sequential-thinking
mcp__sequential-thinking__create_thinking_chain(task)

# datetime
mcp__datetime__get_current_datetime(timezone)
```

### Batch 2: Research

```
# brave-search
mcp__brave-search__brave_web_search(query, count)

# arxiv
mcp__arxiv__search_papers(query, max_results)

# perplexity
mcp__perplexity__perplexity_search(query, max_results)

# wikipedia
mcp__wikipedia__search(query)
```

### Batch 3: Utilities

```
# desktop-commander
mcp__desktop-commander__list_sessions()

# chroma
mcp__chroma__chroma_list_collections()

# gptresearcher
mcp__gptresearcher__quick_search(query)
```

### Batch 4: Specialized

```
# playwright
mcp__playwright__browser_navigate(url)
mcp__playwright__browser_close()

# lotus-wisdom
mcp__lotus-wisdom__lotuswisdom(tag, content, stepNumber, totalSteps, nextStepNeeded)
```

---

## Expected Outcomes

### Per-Batch Results

| Batch | MCPs | Expected Status |
|-------|------|-----------------|
| Batch 1 | 8 | All tools loaded |
| Batch 2 | 8 | All tools loaded |
| Batch 3 | 7 | All tools loaded |
| Batch 4 | 6 | All tools loaded |

### Full Validation

After all 4 batches:
- 17 MCPs tested in isolation
- All tools confirmed functional
- No "Connected but no tools" issues
- Token cost estimates verified

---

## Integration with Validation Harness

This pattern extends the MCP Validation Harness (mcp-validation-harness.md):

1. **Phase 1-3**: Run once per batch after /clear
2. **Phase 4**: Functional tests per batch
3. **Phase 5**: Aggregate results across all batches

The batch approach ensures Phase 4 tests can actually execute because tools are guaranteed to be loaded.

---

## When to Use Batch Validation

| Scenario | Approach |
|----------|----------|
| Initial MCP setup | Full batch validation (all 4 batches) |
| Adding new MCP | Single batch containing new MCP |
| Troubleshooting | Isolate to specific batch |
| Regression testing | Full batch validation |
| Quick verification | Current session tools only |

---

*Batch MCP Validation Pattern — v1.0*

# Skill Testing Pattern

**Purpose**: Ensure new skills work correctly before considering them complete
**Created**: 2026-01-22

---

## Principle

**A skill is not complete until it has been tested end-to-end.**

Dry-runs and syntax checks are insufficient. Skills must be tested with real execution to verify:
1. All components are wired correctly
2. Permissions and paths work
3. Output is as expected
4. Error handling functions

---

## Testing Checklist

### 1. Structural Verification

Before any execution:

- [ ] Skill directory exists with required files (SKILL.md, commands/)
- [ ] All symlinks resolve correctly
- [ ] paths-registry.yaml updated
- [ ] Skills index updated
- [ ] Command frontmatter is valid (allowed-tools, description)

### 2. Dry-Run Testing

Test without side effects:

```bash
# If skill supports --dry-run
/skill-command "test input" --dry-run

# Verify:
# - Arguments parsed correctly
# - No errors thrown
# - Output format is correct
```

### 3. Happy Path Testing

Execute the primary use case:

```bash
# Run the most common invocation
/skill-command "realistic test input" --typical-options

# Verify:
# - Execution completes without error
# - Output is correct and usable
# - Side effects occurred as expected (files created, etc.)
# - Cost/resources used are reasonable
```

### 4. Edge Case Testing

Test boundary conditions:

| Test Case | What to Verify |
|-----------|----------------|
| Missing required params | Clear error message |
| Invalid param values | Graceful rejection |
| Empty/minimal input | Doesn't crash |
| Large/complex input | Handles within limits |
| Permission issues | Helpful error, not cryptic failure |

### 5. Cross-System Testing (if applicable)

If skill works across multiple contexts:

```bash
# Test from primary system
cd . && /skill-command "test"

# Test from secondary system
cd ~/CreativeProjects && /skill-command "test"

# Verify same behavior in both
```

### 6. Output Verification

Check all output modes:

- [ ] Default output is human-readable
- [ ] JSON output (if supported) is valid JSON
- [ ] Files created are in correct location
- [ ] Obsidian embeds work (if applicable)

---

## Test Documentation Template

When testing a skill, document results:

```markdown
## Skill Test Results: <skill-name>

**Date**: YYYY-MM-DD
**Tester**: Claude / Human

### Tests Performed

| Test | Input | Expected | Actual | Pass |
|------|-------|----------|--------|------|
| Dry run | "test prompt" --dry-run | Enhanced prompt shown | ✓ | ✓ |
| Happy path | "real prompt" --workspace foo | Image generated | ✓ | ✓ |
| Missing workspace | "prompt" (no -w or -o) | Error message | ✓ | ✓ |
| Invalid workspace | --workspace nonexistent | Error message | ? | ? |

### Issues Found

- None / List issues

### Notes

Any observations about behavior, performance, edge cases.
```

---

## Integration with Skill Development

### When Creating Skills

```
1. Design skill structure
2. Implement SKILL.md and commands
3. Set up symlinks/paths
4. Update registries
5. **Run full test suite**  ← Required before "done"
6. Document test results
7. Commit with test evidence
```

### Minimum Viable Test

At bare minimum, every skill must pass:

1. **One successful execution** of the primary command
2. **One error case** to verify error handling
3. **Output verification** confirming result is usable

---

## Examples

### Good Test (Image Generation Skill)

```bash
# 1. Dry run - verify prompt enhancement
/image "test portrait" --workspace teenagers --dry-run
# Expected: See enhanced prompt, no API call

# 2. Happy path - actual generation
/image "portrait of a friendly tavern keeper, middle-aged human male" \
  --workspace teenagers --json
# Expected: Image file created, JSON output with path and embed

# 3. Error case - missing output spec
/image "test"
# Expected: Clear error about needing --workspace or --output

# 4. Validation test (if applicable)
/image "NPC portrait" --workspace teenagers --validate --max-retries 1
# Expected: Validation runs, retries if needed
```

### Bad Test (Insufficient)

```bash
# Only checking dry-run
/image "test" --dry-run
# This tells us nothing about actual execution!
```

---

## Automation Opportunity

For frequently-updated skills, consider:

1. **Test script** in `skill/tests/` directory
2. **CI integration** via hooks
3. **Regression suite** for critical skills

---

## Related

- @.claude/skills/_index.md - Skill directory structure
- @.claude/context/patterns/code-before-prompts-pattern.md - Deterministic tools
- @.claude/context/standards/severity-status-system.md - Issue classification

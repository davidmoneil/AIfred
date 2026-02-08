# TDD Enforcement Pattern

**Purpose**: Ensure code changes are backed by tests. Prevent "it should work" claims without evidence.

**Source**: Extracted from [claude-night-market/imbue](https://github.com/athola/claude-night-market) — proof-of-work TDD enforcement.

## Core Principle

**No implementation without verification.** Before claiming a change works:
1. A test must exist that exercises the change
2. The test must actually be run
3. The test output must be observed (not assumed)

## When to Apply

| Context | TDD Required | Reason |
|---------|-------------|--------|
| New functions/classes | Yes | Verify behavior from start |
| Bug fixes | Yes | Reproduce bug first, then fix |
| Refactors | Yes | Ensure behavior preserved |
| Config/docs changes | No | No executable behavior |
| Skill/pattern files | No | Markdown, not code |
| Infrastructure scripts | Partial | Test critical paths only |

## Pattern

```
1. BEFORE writing implementation:
   a. Check if test file exists for target module
   b. If no test: write test first (Red phase)
   c. Run test — confirm it FAILS (proves test is real)

2. Write implementation (Green phase):
   a. Make minimal change to pass test
   b. Run test — confirm it PASSES
   c. Observe output (don't trust exit code alone)

3. Refactor (optional):
   a. Clean up implementation
   b. Run tests again — confirm still passing
```

## Anti-Patterns

- **Cargo-cult testing**: Writing tests that can't fail (always pass regardless of implementation)
- **Theoretical completion**: Claiming "it should work" without running tests
- **Test-after-only**: Writing tests only after implementation (misses design feedback)
- **Ignoring test output**: Trusting exit code without reading actual assertions

## Proof-of-Work Verification

Before marking any code task as complete, verify:
- [ ] Test(s) exist for the changed code
- [ ] Test(s) were actually executed (show output)
- [ ] Test(s) pass with the change
- [ ] Test(s) would fail without the change (if practical to verify)

## Integration with Validation Skill

The `self-ops` router (→ `validation`) can check for test coverage gaps. The TDD pattern provides the workflow; validation provides the audit.

## Reversibility Score (from attune)

For decisions about test scope, use reversibility assessment:
- **Low reversibility** (RS > 0.6): Full test suite required, no shortcuts
- **Medium reversibility** (RS 0.4-0.6): Key path tests sufficient
- **High reversibility** (RS < 0.4): Smoke test acceptable

## Related

- `wiggum-loop-pattern.md` — Iterative execution with verification steps
- `milestone-review-pattern.md` — Completion gate (requires tests to pass)

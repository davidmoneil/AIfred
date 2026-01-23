# One-Shot PRD v2: Aion Hello Console

*Version: 2.0.0*
*Created: 2026-01-18*
*Based on: Demo A execution 2026-01-18*
*Status: Validated benchmark*

---

## Purpose

This is a **comprehensive, validated product specification** designed to benchmark Jarvis autonomous development capabilities. It serves as:

1. **Regression test** for Jarvis autonomic systems
2. **Validation benchmark** for new tools, MCPs, and expansions
3. **Training exercise** for autonomous product development
4. **Comparison baseline** for measuring improvement over time

### What This Validates

| Capability | Validation Method |
|------------|-------------------|
| Pre-flight verification | External service capability checks |
| TDD methodology | Tests written before implementation |
| Multi-pass verification | Wiggum Loop iteration tracking |
| Self-review | Code review phase execution |
| External integration | GitHub repo creation and push |
| E2E testing | Playwright browser automation |
| Documentation | README, ARCHITECTURE, reports |
| Reporting | Run report + performance analysis |

---

## Product: Aion Hello Console

A minimal web application demonstrating text transformation capabilities.

### Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Aion Hello Console |
| **Type** | Web application (Node.js + Express) |
| **Complexity** | Trivial (validation benchmark) |
| **Target Repo** | `CannonCoPilot/aion-hello-console-<YYYY-MM-DD>` |
| **Expected Duration** | 15-30 minutes |
| **Expected Tests** | 50+ (unit + integration + E2E) |

---

## Phase 1: Pre-flight Verification

### 1.1 Environment Checks

| Check | Command | Required Result |
|-------|---------|-----------------|
| Node.js version | `node --version` | >= 20.0.0 |
| npm version | `npm --version` | >= 10.0.0 |
| Git configured | `git config user.name` | Non-empty |
| Project root exists | `ls /Users/aircannon/Claude/` | Directory exists |

### 1.2 GitHub Capability Verification

**Critical**: Do not just verify authentication. Verify CAPABILITY to perform required operations.

| Check | Method | Required Result |
|-------|--------|-----------------|
| Authentication | `GET /user` | Returns username |
| Repo creation | `POST /user/repos` (test) | 200 or 201 response |
| Push access | Credential helper or PAT with `repo` scope | Verified |

**GitHub Access Methods** (in order of preference):
1. GitHub CLI (`gh`) with authenticated session
2. SSH keys configured for GitHub
3. PAT with `repo` scope via credential helper
4. PAT via GitHub API (curl fallback)

**If GitHub access fails**:
- Document the specific failure
- Request user to provide/update credentials
- Do NOT proceed with PAT embedded in git URL (security risk)

### 1.3 Pre-flight Checklist

```markdown
## Pre-flight Verification Results

- [ ] Node.js: [version]
- [ ] npm: [version]
- [ ] Git user: [username]
- [ ] GitHub auth: [method used]
- [ ] GitHub repo creation: [verified/blocked]
- [ ] Technology stack: Node.js + Express + Vitest + Playwright

**Pre-flight Status**: [PASS/FAIL]
**Blockers**: [list any blockers]
```

---

## Phase 2: Test-Driven Development

### 2.1 Project Scaffolding

Create project structure:

```
aion-hello-console-<YYYY-MM-DD>/
├── .gitignore
├── package.json
├── vitest.config.js
├── playwright.config.js
├── src/
│   ├── index.js           # Entry point
│   ├── api/
│   │   └── app.js         # Express app factory
│   └── utils/
│       └── transform.js   # Transform functions
├── public/
│   └── index.html         # Frontend UI
└── tests/
    ├── unit/
    │   └── transform.test.js
    ├── integration/
    │   └── api.test.js
    └── e2e/
        └── app.spec.js
```

### 2.2 Write Tests First

**Unit Tests** (tests/unit/transform.test.js):

| Function | Test Cases | Min Tests |
|----------|------------|-----------|
| `slugify` | Basic, special chars, spaces, empty, numbers | 5 |
| `reverse` | Basic, empty, single char, with spaces | 4 |
| `uppercase` | Basic, mixed case, empty, with symbols | 4 |
| `wordCount` | Basic, single word, empty, multiple spaces, trim | 5 |
| `transform` | Dispatch to each operation, unknown operation error | 5 |

**Minimum unit tests**: 23

**Integration Tests** (tests/integration/api.test.js):

| Endpoint | Test Cases | Min Tests |
|----------|------------|-----------|
| `POST /api/transform` | Each operation, missing text, missing operation, unknown operation, empty text | 8 |
| `GET /health` | Returns status ok | 1 |

**Minimum integration tests**: 9

**E2E Tests** (tests/e2e/app.spec.js):

| Category | Test Cases | Min Tests |
|----------|------------|-----------|
| Page Load | Title, subtitle, input, dropdown, button, options | 6 |
| Slugify | Basic transform, special characters | 2 |
| Reverse | Basic, sentence | 2 |
| Uppercase | Basic, mixed case | 2 |
| Word Count | Basic, single word, multiple spaces | 3 |
| User Experience | Loading state, clear previous, empty input | 3 |
| Keyboard | Enter key submission | 1 |
| Visual | Output area visibility | 1 |
| API | Health endpoint | 1 |

**Minimum E2E tests**: 21

### 2.3 Verify Tests Fail

Before implementation, run tests and verify they fail with "Not implemented" or similar errors. This confirms TDD setup is correct.

```bash
npm test  # Should show failures
```

---

## Phase 3: Implementation

### 3.1 Transform Functions

Implement in `src/utils/transform.js`:

```javascript
// Required exports
export function slugify(text) { /* ... */ }
export function reverse(text) { /* ... */ }
export function uppercase(text) { /* ... */ }
export function wordCount(text) { /* ... */ }
export function transform(text, operation) { /* ... */ }
```

**Behavior Specifications**:

| Function | Input | Output | Edge Cases |
|----------|-------|--------|------------|
| `slugify` | "Hello World!" | "hello-world" | Empty → "", special chars removed |
| `reverse` | "hello" | "olleh" | Empty → "", preserves spaces |
| `uppercase` | "hello" | "HELLO" | Empty → "", preserves non-alpha |
| `wordCount` | "hello world" | "2 words" | Empty → "0 words", single → "1 word" |
| `transform` | (text, op) | Dispatches | Unknown op → throw Error |

### 3.2 Express API

Implement in `src/api/app.js`:

```javascript
export function createApp() {
  // Factory pattern for testability
  const app = express();

  // Middleware: cors, json, static
  // Routes: GET /health, POST /api/transform

  return app;
}
```

**API Contract**:

| Endpoint | Method | Request | Response (200) | Response (400) |
|----------|--------|---------|----------------|----------------|
| `/health` | GET | - | `{ status: "ok", timestamp }` | - |
| `/api/transform` | POST | `{ text, operation }` | `{ result, timestamp }` | `{ error }` |

### 3.3 Frontend UI

Implement in `public/index.html`:

**Required Elements**:
- `<h1>` with title "Aion Hello Console"
- `<input id="text-input">` for text entry
- `<select id="operation-select">` with 4 operations
- `<button id="submit-btn">` labeled "Transform"
- `<div id="output">` for results (initially hidden)
- `<div id="result-text">` for transformed text
- `<div id="result-timestamp">` for timestamp

**Required Behavior**:
- Submit on button click
- Submit on Enter key in input
- Show loading state during API call
- Display result and timestamp
- Handle errors gracefully

**Styling** (optional but recommended):
- Dark theme
- Centered container
- Gradient title
- Responsive design

### 3.4 Entry Point

Implement in `src/index.js`:

```javascript
import { createApp } from './api/app.js';
const PORT = process.env.PORT || 3000;
const app = createApp();
app.listen(PORT, () => console.log(`Running on port ${PORT}`));
```

---

## Phase 4: Validation

### 4.1 Run All Tests

```bash
npm test           # Unit + Integration (Vitest)
npm run test:e2e   # E2E (Playwright)
npm run test:all   # All tests
```

**Required Results**:
- All unit tests pass (23+)
- All integration tests pass (9+)
- All E2E tests pass (21+)
- Total: 53+ tests, 100% pass rate

### 4.2 Manual Verification

Start server and verify in browser:

```bash
npm start
# Open http://localhost:3000
```

**Manual Checks**:
- [ ] Page loads correctly
- [ ] Input accepts text
- [ ] Each operation works (test all 4)
- [ ] Result displays with timestamp
- [ ] Error handling works (if applicable)

### 4.3 Screenshot Capture (Optional)

Capture screenshots of each operation for visual validation:

```bash
# Save to test-results/ directory
# Screenshot naming: operation-name.png
```

### 4.4 Code Review

Self-review checklist:

| Category | Check |
|----------|-------|
| Structure | Clean separation of concerns |
| Testability | Factory pattern, pure functions |
| Error handling | Input validation, try/catch |
| Security | textContent not innerHTML, no XSS |
| Documentation | JSDoc comments on exports |

---

## Phase 5: Documentation

### 5.1 README.md

**Required Sections**:
1. Title and description
2. Overview table (type, stack, purpose)
3. Features list (4 operations)
4. Prerequisites
5. Installation instructions
6. Running the application
7. Running tests (all three types)
8. API documentation (endpoints, request/response)
9. Project structure
10. License

### 5.2 ARCHITECTURE.md

**Required Sections**:
1. Overview
2. Technology choices (with rationale)
3. Design decisions (factory pattern, separation)
4. Data flow diagram
5. Testing strategy
6. Security considerations
7. Future considerations

---

## Phase 6: Delivery

### 6.1 Git Operations

```bash
# Initialize
git init
git add .
git commit -m "Initial commit: Aion Hello Console v1.0.0"

# Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
```

### 6.2 GitHub Repository

**Creation Method** (in order of preference):
1. `gh repo create` (if gh CLI available)
2. GitHub API via curl
3. Manual creation (document as limitation)

**Repository Settings**:
- Name: `aion-hello-console-<YYYY-MM-DD>`
- Visibility: Public
- Description: "Aion Hello Console - Jarvis autonomy benchmark demo"
- No README init (we provide our own)

### 6.3 Push Code

```bash
git remote add origin <repo-url>
git push -u origin main --tags
```

### 6.4 Verify Delivery

- [ ] Repository exists at expected URL
- [ ] Code visible on GitHub
- [ ] Release tag visible
- [ ] README renders correctly

---

## Phase 7: Reporting

### 7.1 Run Report

Generate: `projects/project-aion/reports/aion-hello-console-run-report-<YYYY-MM-DD>.md`

**Required Content**:

```markdown
# Aion Hello Console Run Report

**Execution Date**: <date>
**Status**: COMPLETE | PARTIAL | BLOCKED

## Execution Details
| Metric | Value |
|--------|-------|
| Duration | <time> |
| Technology | Node.js + Express |
| Repository | <URL> |

## Test Results
| Type | Count | Passed | Failed |
|------|-------|--------|--------|
| Unit | N | N | 0 |
| Integration | N | N | 0 |
| E2E | N | N | 0 |

## Requirements Checklist
[All success criteria with status]

## Issues Encountered
[Any blockers or workarounds]

## Recommendations
[Improvements for future runs]
```

### 7.2 Performance Analysis Report

Generate: `projects/project-aion/reports/aion-hello-console-analysis-<YYYY-MM-DD>.md`

**Required Content**:

```markdown
# Performance Analysis

## Autonomic System Alignment
| System | Expected | Actual | Alignment |
|--------|----------|--------|-----------|
| AC-01 | ... | ... | % |
| AC-02 | ... | ... | % |

## Iteration Statistics
- Wiggum Loop iterations: N
- Self-reviews: N
- Corrections: N

## Lessons Learned
[Key findings]

## Recommendations
[Improvement proposals]
```

---

## Success Criteria

### Functional Requirements

| ID | Requirement | Validation Method |
|----|-------------|-------------------|
| F-1 | Web UI renders correctly | E2E test + screenshot |
| F-2 | Text input accepts user input | E2E test |
| F-3 | Operation dropdown has 4 options | E2E test |
| F-4 | Button triggers transformation | E2E test |
| F-5 | Output displays transformed text | E2E test |
| F-6 | Timestamp included in response | Integration test |
| F-7 | Slugify operation works | Unit + E2E test |
| F-8 | Reverse operation works | Unit + E2E test |
| F-9 | Uppercase operation works | Unit + E2E test |
| F-10 | Word count operation works | Unit + E2E test |
| F-11 | Error handling for invalid input | Integration test |
| F-12 | Health endpoint responds | Integration test |

### Quality Requirements

| ID | Requirement | Validation Method |
|----|-------------|-------------------|
| Q-1 | All unit tests pass | Test suite |
| Q-2 | All integration tests pass | Test suite |
| Q-3 | All E2E tests pass | Playwright |
| Q-4 | 50+ total tests | Test count |
| Q-5 | README complete | Manual review |
| Q-6 | ARCHITECTURE complete | Manual review |
| Q-7 | Code review passed | Self-review checklist |

### Delivery Requirements

| ID | Requirement | Validation Method |
|----|-------------|-------------------|
| D-1 | Repository created on GitHub | URL accessible |
| D-2 | Correct naming convention | Repo name check |
| D-3 | Main branch has code | GitHub UI |
| D-4 | Release tag v1.0.0 exists | Git tags |
| D-5 | Run report generated | File exists |
| D-6 | Analysis report generated | File exists |

### Safety Requirements

| ID | Requirement | Validation Method |
|----|-------------|-------------------|
| S-1 | No operations outside allowed paths | Audit log |
| S-2 | No secrets in repository | Grep for tokens |
| S-3 | No credentials in git config | Check remote URL |
| S-4 | Full audit trail available | Session history |

---

## Autonomic System Validation Points

Track these during execution:

### AC-01: Self-Launch
- [ ] Context loaded at session start
- [ ] Autonomous work initiation
- [ ] No "awaiting instructions"

### AC-02: Wiggum Loop
- [ ] TodoWrite used for tracking
- [ ] Multi-pass verification on each phase
- [ ] Blocker investigation (not stopping)
- [ ] Count total iterations

### AC-03: Milestone Review
- [ ] Technical review (code quality)
- [ ] Progress review (PRD checklist)
- [ ] Issues documented

### AC-05: Self-Reflection
- [ ] Lessons captured
- [ ] Issues documented with root cause
- [ ] Improvements proposed

### AC-09: Session Completion
- [ ] Reports generated
- [ ] Session state updated
- [ ] Clean handoff

---

## Troubleshooting Guide

### Issue: GitHub PAT Cannot Create Repos

**Symptoms**: `403 Resource not accessible by personal access token`

**Diagnosis**:
```bash
curl -sI -H "Authorization: token <PAT>" https://api.github.com/user | grep x-oauth-scopes
```

**Resolution**: PAT needs `repo` scope (classic) or `Contents: Read and write` + `Administration: Read and write` (fine-grained)

### Issue: Server Connection Refused

**Symptoms**: `ERR_CONNECTION_REFUSED` at localhost:3000

**Diagnosis**:
```bash
lsof -i :3000
```

**Resolution**: Start server with `npm start`. For persistence: `nohup npm start > server.log 2>&1 &`

### Issue: Playwright Tests Fail

**Symptoms**: E2E tests timeout or can't find elements

**Diagnosis**: Check if server is running and accessible

**Resolution**: Playwright config should auto-start server via `webServer` option

### Issue: Tests Pass But Manual Verification Fails

**Symptoms**: Tests green but UI doesn't work in browser

**Diagnosis**: Check browser console for errors

**Resolution**: Ensure `express.static('public')` is configured, check file paths

---

## Execution Checklist

Use this checklist when executing the PRD:

```markdown
## Execution Checklist

### Pre-flight
- [ ] Node.js version verified
- [ ] GitHub capability verified (not just auth)
- [ ] Technology stack confirmed

### TDD Setup
- [ ] Project structure created
- [ ] Unit tests written (23+)
- [ ] Integration tests written (9+)
- [ ] E2E tests written (21+)
- [ ] Tests fail before implementation

### Implementation
- [ ] Transform functions implemented
- [ ] Unit tests pass
- [ ] Express API implemented
- [ ] Integration tests pass
- [ ] Frontend UI implemented
- [ ] E2E tests pass

### Validation
- [ ] All tests pass (53+)
- [ ] Manual browser verification
- [ ] Code review completed
- [ ] Screenshots captured (optional)

### Documentation
- [ ] README.md complete
- [ ] ARCHITECTURE.md complete

### Delivery
- [ ] Git repository initialized
- [ ] GitHub repo created
- [ ] Code pushed
- [ ] Release tag created
- [ ] Delivery verified

### Reporting
- [ ] Run report generated
- [ ] Analysis report generated
- [ ] Session state updated
```

---

## Comparison Baseline

### Demo A Results (2026-01-18)

| Metric | Value |
|--------|-------|
| Duration | ~30 minutes (including issue resolution) |
| Unit Tests | 23 |
| Integration Tests | 9 |
| E2E Tests | 21 |
| Total Tests | 53 |
| Pass Rate | 100% |
| Wiggum Iterations | ~35 |
| PRD Requirements | 27/27 |
| Issues Encountered | 2 (GitHub PAT, server persistence) |

Use these as baseline for comparison in future runs.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-05 | Initial template |
| 2.0.0 | 2026-01-18 | Comprehensive rewrite based on Demo A execution |

---

## Related Documents

- `projects/project-aion/reports/demo-a-run-report-2026-01-18.md` — First execution
- `projects/project-aion/reports/demo-a-autonomic-analysis-2026-01-18.md` — Performance analysis
- `projects/project-aion/reports/demo-a-self-assessment-2026-01-18.md` — Self-assessment
- `.claude/context/patterns/project-reporting-pattern.md` — Reporting standard
- `.claude/context/patterns/wiggum-loop-pattern.md` — Multi-pass verification

---

*One-Shot PRD v2.0 — Validated Autonomy Benchmark*
*Execute to validate Jarvis autonomous development capabilities*

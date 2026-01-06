# One-Shot PRD: Aion Hello Console

*Version: 1.0.0*
*Created: 2026-01-05*
*Status: Template (not yet executed)*

---

## Purpose

This is a **minimal, deterministic product specification** designed to be executed end-to-end to evaluate Jarvis autonomy. It validates that Jarvis can:

- Create a new repository
- Scaffold a complete project
- Write functional code with tests
- Generate documentation
- Package and run the application
- Push to GitHub
- Generate a run report

> **Note**: This PRD is a Jarvis artifact. It must not be placed into or modify the AIfred baseline repo.

---

## Product: Aion Hello Console

A minimal web application with a tiny GUI and trivial functionality.

### Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Aion Hello Console |
| **Type** | Web application |
| **Complexity** | Trivial (validation benchmark) |
| **Target Repo** | `CannonCoPilot/aion-hello-console-<timestamp>` |

---

## Requirements

### 1. Web UI

- A single HTML page
- A text input field
- A submit button
- An output area displaying transformed text

**Transformations** (implement at least one):
- Slugify (convert to URL-safe slug)
- Reverse (reverse the string)
- Uppercase (convert to uppercase)
- Word count (count words)

### 2. Backend Endpoint

| Endpoint | Method | Input | Output |
|----------|--------|-------|--------|
| `/api/transform` | POST | `{ "text": "string", "operation": "string" }` | `{ "result": "string", "timestamp": "ISO8601" }` |

**Behavior**:
- Receives text and operation type
- Applies the transformation
- Returns the result with a timestamp

### 3. Tests

#### Unit Tests
- Test the transform function directly
- Cover each supported operation
- Test edge cases (empty string, special characters)

#### Integration Tests
- Test the API endpoint
- Verify request/response format
- Test error handling

### 4. Documentation

#### README.md
Must include:
- Project description
- Prerequisites
- Installation instructions
- How to run the application
- How to run tests
- API documentation

#### Architecture Notes
Short document describing:
- Project structure
- Technology choices
- Design decisions

### 5. Delivery

#### Repository Setup
1. Create repository under `CannonCoPilot/`
2. Name format: `aion-hello-console-<YYYY-MM-DD>` or with version
3. Initialize with proper `.gitignore`

#### Git Operations
1. Create initial commit with scaffolding
2. Add implementation commits
3. Add test commits
4. Tag a release (e.g., `v1.0.0`)

#### Run Report
Generate a report saved to: `/Users/aircannon/Claude/Jarvis/projects/`

Report must include:
- Execution timestamp
- Repository URL
- Commits made
- Tests passed/failed
- Any issues encountered
- Total execution time

---

## Technology Constraints

Choose ONE of the following stacks (document the choice in the run report):

### Option A: Node.js Stack
- **Runtime**: Node.js (LTS)
- **Backend**: Express.js
- **Frontend**: Vite + vanilla JS/HTML
- **Testing**: Vitest or Jest + Playwright

### Option B: Python Stack
- **Runtime**: Python 3.11+
- **Backend**: FastAPI
- **Frontend**: Minimal HTML (served by FastAPI)
- **Testing**: pytest + httpx

### Option C: Minimal Stack
- **Criteria**: Simplest viable given toolchain
- **Constraint**: Must still have tests and API endpoint

---

## Success Criteria

### Functional
- [ ] Web UI renders correctly
- [ ] Text input accepts user input
- [ ] Button triggers transformation
- [ ] Output displays transformed text
- [ ] API endpoint responds correctly
- [ ] Timestamp is included in response

### Quality
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] No linting errors (if linter configured)
- [ ] README is complete and accurate

### Delivery
- [ ] Repository exists under CannonCoPilot
- [ ] Main branch contains all code
- [ ] Release tag exists
- [ ] Run report generated in Jarvis projects directory

### Safety
- [ ] No operations outside allowlisted paths
- [ ] Full audit log trace available
- [ ] No secrets committed to repository

---

## Execution Protocol

When executing this PRD:

1. **Pre-flight**
   - Confirm GitHub access (CannonCoPilot org)
   - Confirm technology stack choice
   - Confirm naming convention

2. **Scaffold**
   - Create project directory at projects root
   - Initialize git repository
   - Create basic structure

3. **Implement**
   - Build backend API
   - Build frontend UI
   - Write tests

4. **Validate**
   - Run all tests
   - Manual verification of UI
   - Check for linting issues

5. **Deliver**
   - Push to GitHub
   - Create release tag
   - Generate run report

6. **Report**
   - Save report to Jarvis projects directory
   - Update any relevant Jarvis documentation

---

## Template Usage

This document serves as a **template** for autonomy benchmarking. To execute:

1. Copy this PRD or reference it directly
2. Make technology stack decision
3. Execute with Jarvis
4. Compare results against success criteria
5. Store run report for comparison with future runs

---

## Related Documents

- @projects/Project_Aion.md — Full roadmap (Section 3 defines this PRD)
- @docs/project-aion/archon-identity.md — Archon context
- @.claude/context/patterns/workspace-path-policy.md — Where outputs go

---

*One-Shot PRD — Autonomy Benchmark for Project Aion*
*Do not execute until PR-11+ (autonomy features) are complete*

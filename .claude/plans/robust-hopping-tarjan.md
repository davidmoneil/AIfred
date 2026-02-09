# Stream 1: Reconstruct Removed MCP Capabilities into research-ops

## Context

Six MCPs were removed during the Decomposition-First migration (v5.9.0), but their unique capabilities need native reconstruction as executable protocols in `research-ops`. Currently, research-ops v2.0.0 has only inline curl templates (a reference card) — the pipeline-design explicitly says "ad-hoc Bash(curl) is NOT an acceptable replacement." This plan creates production-grade executable scripts with error handling, response parsing, and a validation suite.

---

## Milestone 1: Foundation + Core Backends (Implementation)

### 1.1 Create shared utilities
**File**: `.claude/skills/research-ops/scripts/_common.sh`
- `get_credential(key_path)` — Extract from credentials.yaml via yq
- `handle_error(backend, message, http_code)` — Structured stderr errors
- `format_json(data)` — Pretty-print via jq
- `require_command(...)` — Validate yq/jq/curl available
- `url_encode(string)` — URL-encode query parameters

### 1.2 Create 4 core backend scripts (removed MCPs with working keys)

| Script | MCP Replaced | Key Path | Features |
|--------|-------------|----------|----------|
| `scripts/search-brave.sh` | brave-search | `.search.brave` | Web/news/video search, freshness filters, result count |
| `scripts/search-arxiv.sh` | arxiv | None (public) | Category filters, date range, author search, XML→text parsing |
| `scripts/fetch-wikipedia.sh` | wikipedia | None (public) | Multi-language, summary/extract modes, title encoding |
| `scripts/search-perplexity.sh` | perplexity | `.llm.perplexity` | 4 sonar models, citation extraction, timeout handling |

Each script: `#!/usr/bin/env bash`, `set -euo pipefail`, sources `_common.sh`, has `--help`, returns 0/1.

### 1.3 Create 2 workflow documentation scripts (blocked backends)

| Script | MCP Replaced | Status | Reason |
|--------|-------------|--------|--------|
| `scripts/fetch-context7.sh` | context7 | PARTIAL | Requires local-rag MCP for embeddings |
| `scripts/deep-research-gpt.sh` | gptresearcher | BLOCKED | API key not provisioned |

These output JSON workflow instructions (what MCP tools to call, what credentials exist).

### 1.4 Update SKILL.md to v2.1.0
- Replace inline curl templates with script references
- Add Progressive Disclosure section pointing to scripts/
- Keep concise (~350-400 tokens)
- Maintain selection rules decision tree

**Milestone 1 Review**: Run shellcheck on all scripts, verify each executes with `--help`.

---

## Milestone 2: Testing + Validation

### 2.1 Create validation suite
**File**: `.claude/skills/research-ops/scripts/test-all.sh`
- Tests all 4 core backends with real API calls
- Test queries: "Claude AI" (Brave), "transformers" (arXiv), "Artificial_intelligence" (Wikipedia), "What is Claude AI?" (Perplexity)
- Success = valid response structure (JSON/XML), exit code 0
- Reports pass/fail per backend

### 2.2 Run validation
- Execute `bash scripts/test-all.sh`
- Verify all 4 core backends return valid responses
- Document any failures

### 2.3 Error path testing
- Missing credential (rename key temporarily)
- Invalid query (empty string)
- Timeout scenario (if applicable)

**Milestone 2 Review**: All 4 core backends passing. Error paths handled gracefully.

---

## Milestone 3: Code Review + Deep Analysis

### 3.1 Code review (Wiggum Loop)
- Shellcheck static analysis on all `.sh` files
- Bash 3.2 compatibility check (no bash 4+ features)
- Security review: no credentials in scripts/output, proper quoting
- Error handling completeness
- Script structure consistency

### 3.2 Deep analysis: MCP vs native skill comparison
Compare each reconstructed backend against its original MCP:

| Dimension | Check |
|-----------|-------|
| Capability parity | Can the script do everything the MCP tool did? |
| Error handling | MCP server errors vs bash error handling |
| Token cost | MCP tool definition tokens vs script invocation tokens |
| Dependencies | npm/uvx runtime vs bash/curl/jq |
| Discoverability | ToolSearch vs manifest router |
| Credential management | MCP env vars vs centralized yaml |

### 3.3 Revision
- Fix all issues found in review
- Re-run validation suite
- Iterate until clean

**Milestone 3 Review**: Code review APPROVED, all issues fixed, analysis documented.

---

## Milestone 4: Documentation + Commit

### 4.1 Update MCP decomposition registry
**File**: `.claude/context/reference/mcp-decomposition-registry.md`
- Change brave/arxiv/wikipedia/perplexity from PLANNED → DONE
- Change context7 from PLANNED → PARTIAL
- Keep gptresearcher as BLOCKED

### 4.2 Update tool reconstruction backlog
**File**: `.claude/context/reference/tool-reconstruction-backlog.md`
- Update P1 items 1-5 status with script paths

### 4.3 Update session state + priorities
- `.claude/context/session-state.md` — Add Phase 15 (Stream 1)
- `.claude/context/current-priorities.md` — Mark Stream 1 status

### 4.4 Update capability map
**File**: `.claude/context/psyche/capability-map.yaml`
- Update research-ops version to 2.1.0

### 4.5 Commit and push
- Stage all new/modified files
- Commit: `feat: research-ops v2.1.0 — native MCP capability reconstruction (Stream 1)`
- Push to origin/Project_Aion

---

## Files to Create (8 new)

| File | Purpose |
|------|---------|
| `scripts/_common.sh` | Shared utilities (credential extraction, error handling) |
| `scripts/search-brave.sh` | Brave Search API integration |
| `scripts/search-arxiv.sh` | arXiv paper search |
| `scripts/fetch-wikipedia.sh` | Wikipedia REST API |
| `scripts/search-perplexity.sh` | Perplexity AI search (4 models) |
| `scripts/fetch-context7.sh` | Context7 workflow doc (local-rag) |
| `scripts/deep-research-gpt.sh` | GPTResearcher workflow doc (blocked) |
| `scripts/test-all.sh` | Validation suite |

## Files to Modify (5 existing)

| File | Change |
|------|--------|
| `research-ops/SKILL.md` | v2.0.0 → v2.1.0, add script references |
| `mcp-decomposition-registry.md` | PLANNED → DONE/PARTIAL/BLOCKED |
| `tool-reconstruction-backlog.md` | Update P1 status |
| `session-state.md` | Add Phase 15 |
| `current-priorities.md` | Mark Stream 1 status |

## Verification

1. `bash scripts/test-all.sh` — All 4 core backends pass
2. `shellcheck scripts/*.sh` — No errors (warnings acceptable)
3. `grep -c "PLANNED" mcp-decomposition-registry.md` — Count decreases
4. `grep "version: 2.1.0" research-ops/SKILL.md` — Version bumped

## Success Criteria

- 4/6 backends executable and tested (brave, arxiv, wikipedia, perplexity)
- Context7 workflow documented (MCP integration pattern)
- GPTResearcher workflow documented (blocked, pending key)
- Validation suite passing
- Code review clean (shellcheck + manual)
- MCP vs skill analysis documented
- Registry/backlog/session state all updated
- Committed and pushed

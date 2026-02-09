# Integrations

**Purpose**: Tool, MCP, and capability integration documentation.

**Layer**: Nous (tool knowledge)

**Last Updated**: 2026-02-08

---

## Status Overview

> **v5.9.0 NOTE**: The MCP decomposition milestone (Feb 2026) removed 13 MCPs
> and replaced them with skills. Many docs here predate this change. The
> authoritative selection guide is now `.claude/context/psyche/capability-map.yaml`.

## Contents

| Document | Status | Notes |
|----------|--------|-------|
| `capability-map.yaml` | PARTIALLY OUTDATED | File/Git ops tables still valid; research section superseded by research-ops v2.0 |
| `mcp-installation.md` | LARGELY OUTDATED | Only Memory MCP section remains accurate; 13 MCPs removed |
| `overlap-analysis.md` | PARTIALLY OUTDATED | Most overlaps resolved by decomposition; remaining MCP overlaps still valid |
| `skills-selection-guide.md` | CURRENT | Plugin/skill selection for document types, visuals |
| `memory-usage.md` | OUTDATED | Docker Desktop references incorrect; see knowledge-ops v2.0 |
| `search-api-research.md` | SUPERSEDED | See `.claude/skills/research-ops/SKILL.md` v2.0 (14 backends) |
| `overlap-analysis-workflow.md` | HISTORICAL | Process doc for overlap analysis |
| `capability-matrix-update-workflow.md` | HISTORICAL | Process doc for matrix updates |
| `tooling-evaluation-workflow.md` | HISTORICAL | Process doc for tool evaluation |

## Current Authoritative Sources

| Need | Document |
|------|----------|
| Tool/skill selection | `.claude/context/psyche/capability-map.yaml` (manifest router) |
| MCP decomposition history | `.claude/context/reference/mcp-decomposition-registry.md` v5.0 |
| Research tool selection | `.claude/skills/research-ops/SKILL.md` v2.0 |
| Memory system | `.claude/skills/knowledge-ops/SKILL.md` v2.0 |
| Skill descriptions | `.claude/context/reference/skill-descriptions.csv` |

## Usage

When uncertain about tool selection:
1. Check `capability-map.yaml` first (manifest router)
2. For research: consult research-ops skill
3. For memory: consult knowledge-ops skill
4. For overlap questions: check `overlap-analysis.md` (for remaining MCPs)

---

*Jarvis — Nous Layer*

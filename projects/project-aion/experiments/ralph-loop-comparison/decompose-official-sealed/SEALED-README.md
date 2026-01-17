# SEALED: Decompose-Official

**Sealed Date**: 2026-01-17
**Purpose**: Prevent cross-contamination during blind build of Decompose-Native

## Experimental Protocol

This directory contains the **Decompose-Official** tool built during Phase 1 of the
Ralph Loop Comparison Experiment. These files are **SEALED** and must NOT be read,
referenced, or used in any way during:

- Phase 3: Building Decompose-Native (blind build)
- Phase 4: Validating Decompose-Native
- Phase 5: Integration testing with Decompose-Native

## Contents

| File | Description |
|------|-------------|
| `plugin-decompose.sh` | Main decomposition script (~1100 lines) |
| `plugin-decompose.md` | Command frontmatter file |
| `plugin-decompose/SKILL.md` | Skill documentation (v2.0.0) |

## Build Context

- **Build Tool**: Official `/ralph-loop:ralph-loop` plugin
- **Iterations**: Multiple (Phase 1: initial build, Enhancement: --execute feature)
- **Validation**: All 8 features tested against example-plugin
- **Integration Test**: Successfully integrated ralph-loop plugin (Phase 2A)

## Unseal Conditions

These files may ONLY be unsealed for:
1. Phase 6: Side-by-side comparison analysis
2. Post-experiment archival

**DO NOT OPEN BEFORE PHASE 6**

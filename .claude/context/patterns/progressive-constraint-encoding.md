# Progressive Constraint Encoding

**Category**: Prompt Engineering
**Created**: 2026-02-08
**Source**: Deck-ops skill development (3-iteration cycle)
**Pattern #**: 51

---

## Problem

When instructing an LLM agent to generate complex artifacts (presentations, documents, code), abstract quality goals ("make it polished", "don't overlap") are insufficient. The agent needs concrete implementation constraints to produce correct output.

## Solution

Encode constraints at three progressive levels, each catching more issues:

### Level 1: Intent (~40% issue detection)
> "Make it look polished and professional"

Communicates **what** you want but not **how** to achieve it. Agent uses its own judgment for all implementation decisions.

### Level 2: Quality Attributes (~70% issue detection)
> "No text overlap, speaker notes on every slide, font sizes 18pt+"

Specifies **measurable quality criteria** but leaves the agent to figure out how to satisfy them. Works for experienced agents with domain knowledge.

### Level 3: Implementation Constraints (~85% issue detection)
> "Left column max 7.5 inches, right column starts at 8.5, 0.5-inch gutter, y-cursor for vertical stacking"

Provides **concrete dimensions, algorithms, and patterns** that directly prevent failure modes. Most effective for spatial/layout/precision tasks.

## The Remaining ~15%

Implementation constraints plateau at ~85%. The remaining gap requires **actual rendering verification** — opening the artifact in its native application and visually confirming correctness. No amount of prompt engineering replaces runtime validation.

## When to Apply

- Artifact generation (slides, documents, diagrams, layouts)
- Any task where spatial precision matters
- Prompt engineering for skills/tools that generate complex output
- Iterative skill development — start at Level 1, add constraints based on observed failures

## Anti-Pattern

Over-constraining on the first iteration. Start with intent, observe failures, add constraints targeted at specific failure modes. This produces minimal, effective constraints rather than exhaustive specifications.

---

*Discovered during deck-ops skill v1.0.0 → v1.2.0 development cycle.*

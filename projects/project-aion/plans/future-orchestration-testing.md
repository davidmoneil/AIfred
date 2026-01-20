# Future Testing: Jarvis Orchestration Layer

**Created**: 2026-01-20
**Status**: Planning Notes (for post-autonomic testing)
**Reference**: User feedback during Session 1 of Autonomic Testing Protocol

---

## Overview

After the Autonomic Systems Testing Protocol (AC-01 through AC-09) completes, a second testing layer is needed for the **orchestration and intelligence systems** that sit above the autonomic components.

These three systems work together to make Jarvis a "thinking and planning orchestration agent" and "session manager agent":

1. **Jarvis Orchestration Agent** — Top-layer central agent and persona
2. **PR-9: Selection Intelligence Pattern** — Research-backed tool modality framework
3. **PR-8: MCP Expansion + Context Budget Management** — Validation harness

---

## System 1: Jarvis Orchestration Agent

### Description
The central persona and decision-making layer that:
- Coordinates between autonomic components
- Maintains persona consistency (Jarvis identity)
- Makes strategic decisions about task approach
- Manages multi-session continuity

### Test Categories
- [ ] Persona consistency under stress
- [ ] Decision-making quality (tool selection, approach)
- [ ] Task decomposition accuracy
- [ ] Multi-session context preservation
- [ ] User intent interpretation
- [ ] Autonomous vs. assisted mode switching

### Key Files
- `.claude/CLAUDE.md` (master instructions)
- `.claude/persona/jarvis-identity.md`
- `.claude/context/patterns/startup-protocol.md`

---

## System 2: PR-9 Selection Intelligence Pattern

### Description
Research-backed framework for intelligent tool and modality selection:
- Agent selection patterns
- MCP selection based on task
- Plugin vs. skill vs. agent decisions
- Context-aware capability matching

### Test Categories
- [ ] Correct agent selection for task types
- [ ] MCP selection accuracy
- [ ] Tool modality decisions (when to use what)
- [ ] Fallback behavior when preferred tool unavailable
- [ ] Selection under context pressure

### Key Files
- `.claude/context/patterns/selection-intelligence-guide.md`
- `.claude/context/patterns/agent-selection-pattern.md`
- `.claude/context/integrations/capability-matrix.md`

---

## System 3: PR-8 MCP Expansion + Context Budget

### Description
MCP ecosystem management and context budget enforcement:
- MCP tier classification (Tier 1, 2, 3)
- Dynamic MCP enable/disable
- Context budget tracking and enforcement
- Validation harness for MCP health

### Test Categories
- [ ] MCP tier assignments correct
- [ ] Dynamic disable/enable works
- [ ] Context budget warnings fire correctly
- [ ] Validation harness catches issues
- [ ] MCP health monitoring

### Key Files
- `.claude/context/patterns/context-budget-management.md`
- `.claude/scripts/disable-mcps.sh`
- `.claude/scripts/enable-mcps.sh`
- `.claude/hooks/context-accumulator.js`

---

## Additional Items to Revisit

### MCP Tier Management Review
**User Note**: "I've been meaning to revisit this and give you some feedback on which MCPs I want to keep in each Tier."

Current tiers need user review:
- Tier 1: Always loaded (Memory, Git, Filesystem)
- Tier 2: Loaded on demand (Local RAG, Fetch)
- Tier 3: Specialist (Research tools)

**Action**: Schedule MCP tier review session with user.

### MCP Decomposition to Skills
**User Note**: "Whether plugin decomposition could be applied to MCPs as well, and if so, whether we could leverage this to save a lot of context space by reducing the functionality of an MCP to a claudeCode skill."

**Research Questions**:
1. Can MCP functionality be extracted to skills?
2. What's the context cost difference (MCP vs skill)?
3. Which MCPs are candidates for decomposition?
4. Would this affect capability or just context?

**Potential Benefits**:
- Reduced base context load
- On-demand capability loading
- Finer-grained control

**Action**: Add to R&D agenda for investigation.

---

## Proposed Test Structure

### Phase A: Orchestration Layer Tests
| Test ID | System | Scenario |
|---------|--------|----------|
| ORC-01 | Orchestration | Persona consistency across 10+ interactions |
| ORC-02 | Orchestration | Task decomposition for complex PRD |
| ORC-03 | Orchestration | Multi-session state preservation |
| ORC-04 | Selection | Agent selection accuracy (20 scenarios) |
| ORC-05 | Selection | Tool modality decisions |
| ORC-06 | MCP | Tier enforcement under load |
| ORC-07 | MCP | Dynamic enable/disable cycle |
| ORC-08 | Integration | All three systems under load |

### Phase B: Stress Variants
Similar to autonomic PRD variants, but for orchestration:
- ORC-V1: Persona under conflicting requests
- ORC-V2: Selection with limited tools
- ORC-V3: MCP churn (rapid enable/disable)

---

## Timeline

To be scheduled **after** Autonomic Testing Protocol completes (Sessions 2-5).

Estimated: 2-3 additional sessions

---

*Future Testing: Jarvis Orchestration Layer — Planning Notes*

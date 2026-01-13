---
description: AIfred initial configuration wizard
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, mcp__mcp-gateway__*
---

# AIfred Setup Wizard

You are running the AIfred setup wizard. This will configure your personal AI infrastructure assistant.

## Overview

This setup process will:
0A. **Preflight** — Validate workspace boundaries and environment (PR-4b)
0B. **Prerequisites** — Check and install required software (Git, Docker)
1. **Discovery** — Discover your system and existing infrastructure
2. **Interview** — Understand your goals and preferences
3. **Foundation** — Set up directories, paths, knowledge base
4. **MCP Integration** — Configure MCP servers if desired
5. **Hooks & Automation** — Install automation hooks and guardrails (PR-4a)
6. **Agent Deployment** — Deploy starter agents
7. **Finalization** — Document configuration and verify readiness (PR-4c)

## Setup Phases

Execute each phase in order. Read the phase file and follow its instructions.

**IMPORTANT**: Always complete Phase 0A (Preflight) first. If preflight fails, stop and fix issues before continuing.

### Phase 0A: Environment Preflight (PR-4b)
@setup-phases/00-preflight.md

Validate workspace configuration before setup begins:
- Workspace isolation (Jarvis separate from AIfred baseline)
- Safe working directory (not in forbidden paths)
- Required structure (directories and files)
- Git status (clean tree, correct branch)

**If preflight FAILS**: Stop and fix issues before proceeding.
**If preflight WARNS**: May proceed but note warnings.

### Phase 0B: Prerequisites Check
@setup-phases/00-prerequisites.md

Check and install required dependencies:
- Git (required)
- Docker (recommended - includes detailed Mac/Linux/WSL instructions)
- Node.js/Python (optional, for some MCP servers)

**Note**: This phase clarifies that Homebrew is NOT required for Docker on Mac.
Docker Desktop can be installed directly from docker.com.

### Phase 1: System Discovery
@setup-phases/01-system-discovery.md

Discover the system environment:
- Operating system and hardware
- Docker installation status
- Existing services and containers
- Network configuration
- Storage mounts

### Phase 2: Purpose Interview
@setup-phases/02-purpose-interview.md

Understand user goals through outcome-focused questions:
- Primary use cases
- Automation preferences
- Focus areas (infrastructure/development/both)
- Integration needs

### Phase 3: Foundation Setup
@setup-phases/03-foundation-setup.md

Create the core structure:
- paths-registry.yaml with discovered paths
- Knowledge base templates
- External sources directory
- Initial context files

### Phase 4: MCP Integration
@setup-phases/04-mcp-integration.md

Set up MCP servers based on needs:
- **Auto-install Stage 1 MCPs** (PR-10.5):
  ```bash
  .claude/scripts/setup-mcps.sh --tier1-only
  ```
- Configure Memory MCP for persistence
- Set up additional MCP servers as needed
- Verify connectivity with `claude mcp list`

**Auto-install script options**:
- `--check-only`: Only check current MCP status
- `--tier1-only`: Install Tier 1 (Always-On) MCPs only (default)
- `--all`: Install Tier 1 + Tier 2 MCPs

### Phase 5: Hooks & Automation
@setup-phases/05-hooks-automation.md

Install automation:
- **Guardrail hooks are pre-registered** (PR-10.5):
  - `workspace-guard.js` - Blocks writes to AIfred baseline
  - `dangerous-op-guard.js` - Blocks destructive commands
  - `secret-scanner.js` - Scans for secrets before commits
  - `permission-gate.js` - Soft-gates policy-crossing operations
- **Auto-install plugins** (PR-10.5):
  ```bash
  .claude/scripts/setup-plugins.sh --core-only
  ```
- End-session workflow (`/end-session`)

**Plugin auto-install script options**:
- `--check-only`: Only check current plugin status
- `--core-only`: Install core plugins only (default)
- `--all`: Install all evaluated ADOPT plugins

### Phase 6: Agent Deployment
@setup-phases/06-agent-deployment.md

Deploy starter agents:
- docker-deployer
- service-troubleshooter
- deep-research
- Initialize agent memory

### Phase 7: Finalization (PR-4c)
@setup-phases/07-finalization.md

Complete setup:
- Generate configuration summary
- Move setup files to archive
- Update CLAUDE.md with configuration
- **Register existing projects** (from discovery or GitHub URLs)
- **Run readiness report** to verify setup success
- Create getting-started guide
- Optional: Initial commit and push

## Execution

**Begin with Phase 0A (Environment Preflight)**. If preflight fails, stop and fix issues.

Then progress through Phase 0B (Prerequisites) and Phases 1-7, asking user questions as specified in each phase file.

**Docker Validation**: After any Docker installation attempt, always re-check status
before proceeding:

```bash
docker info &> /dev/null && echo "✅ Docker running" || echo "❌ Docker not running"
```

**Final Verification**: After Phase 7, run `/setup-readiness` to generate a readiness report confirming setup success. Expected status: READY or READY_WITH_WARNINGS.

---

## Setup Enhancements by PR

| Phase | PR | Enhancement |
|-------|-----|-------------|
| 0A Preflight | PR-4b | Workspace boundary validation |
| 4 MCP | PR-10.5 | Auto-install Stage 1 MCPs (`setup-mcps.sh`) |
| 5 Hooks | PR-4a, PR-10.5 | Guardrail hooks + hook registration |
| 5 Plugins | PR-10.5 | Auto-install core plugins (`setup-plugins.sh`) |
| 7 Finalization | PR-4c | Readiness report verification |

---

*Jarvis Setup Wizard v2.0 — Project Aion Master Archon*
*PR-4: Preflight/Guardrails/Readiness, PR-10.5: Auto-install*

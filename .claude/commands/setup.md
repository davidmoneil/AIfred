---
description: AIfred initial configuration wizard
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, mcp__mcp-gateway__*
---

# AIfred Setup Wizard

You are running the AIfred setup wizard. This will configure your personal AI infrastructure assistant.

## Overview

This setup process will:
0. Check and install prerequisites (Git, Docker)
1. Discover your system and existing infrastructure
2. Understand your goals and preferences
3. Set up the foundation (directories, paths, knowledge base)
4. Configure MCP integration if desired
5. Install automation hooks
6. Deploy starter agents
7. Finalize, register projects, and document your configuration

## Setup Phases

Execute each phase in order. Read the phase file and follow its instructions.

**IMPORTANT**: Always complete Phase 0 first. If dependencies are missing, help install them before continuing.

### Phase 0: Prerequisites Check
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
- Deploy MCP Gateway with Docker
- Configure Memory MCP
- Set up additional MCP servers as needed
- Verify connectivity

### Phase 5: Hooks & Automation
@setup-phases/05-hooks-automation.md

Install automation:
- Core hooks (audit, session, security)
- Cron jobs (log rotation, memory pruning)
- Permission configuration
- End-session workflow

### Phase 6: Agent Deployment
@setup-phases/06-agent-deployment.md

Deploy starter agents:
- docker-deployer
- service-troubleshooter
- deep-research
- Initialize agent memory

### Phase 7: Finalization
@setup-phases/07-finalization.md

Complete setup:
- Generate configuration summary
- Move setup files to archive
- Update CLAUDE.md with configuration
- **Register existing projects** (from discovery or GitHub URLs)
- Create getting-started guide
- Optional: Initial commit and push

## Execution

**Begin with Phase 0 (Prerequisites Check)**. Ensure Git is installed and Docker is
either installed & running OR explicitly skipped.

Then progress through Phases 1-7, asking user questions as specified in each phase file.

**Docker Validation**: After any Docker installation attempt, always re-check status
before proceeding:

```bash
docker info &> /dev/null && echo "✅ Docker running" || echo "❌ Docker not running"
```

After all phases complete, provide a summary of what was configured and next steps.

---

*AIfred Setup Wizard v1.1 - Added Phase 0 Prerequisites, Project Registration*

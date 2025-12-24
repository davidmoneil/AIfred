---
description: AIfred initial configuration wizard
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, mcp__mcp-gateway__*
---

# AIfred Setup Wizard

You are running the AIfred setup wizard. This will configure your personal AI infrastructure assistant.

## Overview

This setup process will:
1. Discover your system and existing infrastructure
2. Understand your goals and preferences
3. Set up the foundation (directories, paths, knowledge base)
4. Configure MCP integration if desired
5. Install automation hooks
6. Deploy starter agents
7. Finalize and document your configuration

## Setup Phases

Execute each phase in order. Read the phase file and follow its instructions.

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
- Create getting-started guide
- Optional: Initial commit and push

## Execution

Begin by reading and executing Phase 1. Progress through each phase, asking user questions as specified in the phase files.

After all phases complete, provide a summary of what was configured and next steps.

---

*AIfred Setup Wizard v1.0*

# Parallel Development Skill - Roadmap

**Created**: 2026-01-17
**Ported**: From AIProjects
**Status**: Complete (MVP)
**Goal**: Autonomous parallel development with rigorous planning, execution, and validation

## Vision

Enable non-developers to describe what they want, answer clarifying questions once, then let Claude autonomously plan, build, test, and deliver working software with minimal intervention.

---

## Implementation Phases

### Phase 1: Foundation (Complete)
**Focus**: Basic worktree management and registry

**Tasks**:
- [x] Research and pattern extraction from reference repos
- [x] Create skill structure and documentation
- [x] Implement registry initialization
- [x] Implement worktree create command
- [x] Implement worktree list command
- [x] Implement worktree cleanup command
- [x] Implement worktree status command
- [x] Add port allocation (optional - for dev servers)

**Deliverables**:
- Working `/parallel-dev:worktree-*` commands
- Registry at `.claude/parallel-dev/registry.json`
- Worktrees stored at configurable base path

---

### Phase 2: Planning Workflow (Complete)
**Focus**: Guided requirement gathering and plan creation

**Tasks**:
- [x] Design plan template (PRD-inspired)
- [x] Implement `/parallel-dev:plan` - guided brainstorming
- [x] Implement plan file generation
- [x] Add clarifying question framework
- [x] Implement `/parallel-dev:plan-show`
- [x] Implement `/parallel-dev:plan-edit`
- [x] Implement `/parallel-dev:plan-list`

**Deliverables**:
- Structured planning session flow
- Plan files at `.claude/parallel-dev/plans/{name}.md`
- Question templates for common project types
- Plan template at `.claude/skills/parallel-dev/templates/plan-template.md`

**Key Feature**: Ask all questions upfront, then work autonomously

---

### Phase 3: Task Decomposition (Complete)
**Focus**: Breaking plans into executable tasks

**Tasks**:
- [x] Design task schema (YAML format)
- [x] Implement automatic plan decomposition
- [x] Add dependency graph generation
- [x] Implement parallelization analysis
- [x] Create stream identification logic
- [x] Generate task files with acceptance criteria
- [x] Update status command to show task progress

**Deliverables**:
- Task template at `.claude/skills/parallel-dev/templates/tasks-template.yaml`
- Task files at `.claude/parallel-dev/plans/{name}-tasks.yaml`
- `/parallel-dev:decompose` command
- Dependency visualization in decompose output

---

### Phase 4: Parallel Execution (Complete)
**Focus**: Spawning and coordinating agents

**Tasks**:
- [x] Design execution coordinator
- [x] Implement `/parallel-dev:start`
- [x] Create agent spawning logic (via Task tool)
- [x] Implement progress tracking
- [x] Add dependency-aware scheduling
- [x] Create execution status file template
- [x] Update `/parallel-dev:status` for execution display
- [x] Implement `/parallel-dev:pause`
- [x] Implement `/parallel-dev:resume`

**Deliverables**:
- Execution state template
- Execution tracking at `.claude/parallel-dev/executions/{name}/state.yaml`
- `/parallel-dev:start`, `/parallel-dev:pause`, `/parallel-dev:resume` commands
- Agent coordination via Task tool

**Agent Types**:
- `parallel-dev-implementer` - Code implementation
- `parallel-dev-tester` - Test writing
- `parallel-dev-documenter` - Documentation

---

### Phase 5: QA Validation (Complete)
**Focus**: Automated quality assurance before merge

**Tasks**:
- [x] Design validation pipeline
- [x] Implement `/parallel-dev:validate`
- [x] Create QA validation agent
- [x] Add lint/typecheck integration
- [x] Add test execution
- [x] Add build verification
- [x] Implement acceptance criteria checking
- [x] Generate validation report

**Deliverables**:
- Validation pipeline config
- Validation report template
- `/parallel-dev:validate` command with auto-fix support
- QA validator agent

**Validation Checks**:
1. Lint (eslint, ruff, golangci-lint, clippy)
2. Type check (tsc, mypy, go build)
3. Unit tests (with coverage)
4. Integration tests
5. Build verification
6. Acceptance criteria review

---

### Phase 6: Merge Coordination (Complete)
**Focus**: Safe integration back to main branch

**Tasks**:
- [x] Implement conflict detection
- [x] Implement `/parallel-dev:conflicts`
- [x] Create AI-assisted conflict resolution (--resolve flag)
- [x] Implement `/parallel-dev:merge`
- [x] Add post-merge validation
- [x] Implement automatic cleanup

**Deliverables**:
- `/parallel-dev:conflicts` command
- `/parallel-dev:merge` command with options
- Post-merge validation
- Automatic cleanup

---

## Future Enhancements (Post-MVP)

### GitHub Integration
- [ ] Sync plans to GitHub Issues
- [ ] Create PRs automatically
- [ ] Link commits to tasks
- [ ] Import existing issues as tasks

### Advanced Coordination
- [ ] Agent heartbeat monitoring
- [ ] Stale agent detection and recovery
- [ ] Resource-aware scheduling
- [ ] Priority-based execution

### Learning & Improvement
- [ ] Capture successful patterns
- [ ] Store in Memory MCP for reuse
- [ ] Improve estimates based on history
- [ ] Agent performance metrics

### Templates & Presets
- [ ] Project type templates
- [ ] Stack-specific configurations
- [ ] Company/team standards
- [ ] Reusable task patterns

---

## Technical Decisions

### Why JSON Registry (not SQLite)?
- Simpler to implement and debug
- Human-readable for troubleshooting
- Git-friendly (can version control if needed)
- Sufficient for expected scale

### Why Worktrees (not Branches)?
- True filesystem isolation
- No git index conflicts
- Same `.git` folder (efficient)
- Can run parallel dev servers

### Why tmux (not Ghostty)?
- SSH-compatible
- Scriptable session management
- Cross-platform
- No GUI dependency

### Agent Strategy
- Use built-in subagents for heavy lifting
- Custom agents for specialized workflows
- Main thread as coordinator (conductor pattern)
- Concise summaries back to main context

---

## Dependencies on Existing Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| Git worktrees | Available | Pattern documented |
| Orchestration | Available | Task decomposition |
| Custom agents | Available | `.claude/agents/` |
| Task tool (subagents) | Available | Built-in |
| Memory MCP | Available | Context persistence |
| Session management | Available | State tracking |

---

## Related Documentation

- Skill definition: `.claude/skills/parallel-dev/SKILL.md`
- Worktree pattern: `.claude/context/patterns/worktree-shell-functions.md`
- Agent system: `.claude/context/systems/agent-system.md`
- Orchestration: `.claude/orchestration/README.md`

---

## Changelog

### 2026-01-17 - Ported to AIfred
- Ported from AIProjects with path generalizations
- Updated config.json for configurable paths
- Maintained all 6 phases of functionality
